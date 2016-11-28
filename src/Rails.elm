module Rails exposing (Error(..), get, post, send, fromJson, always, decoder, csrfToken)

{-|

# Http
@docs Error, get, post, send, fromJson, always, decoder

# Tokens
@docs csrfToken

-}

import Http
import Task exposing (Task, succeed, fail, mapError, andThen)
import Json.Decode exposing (Decoder, decodeString)
import Result exposing (Result)
import String
import Native.Rails


-- Http


{-| The kinds of errors a Rails server may return.
-}
type Error error
  = HttpError Http.Error
  | RailsError error


{-| Send a GET request to the given URL. You also specify how to decode the response.

    import Json.Decode (list, string)

    hats : Task (Error (List String)) (List String)
    hats =
      get (decoder (list string) (succeed ())) "http://example.com/hat-categories.json"

-}
get : ResponseDecoder error value -> String -> Task (Error error) value
get decoder url =
  fromJson decoder (send "GET" url Http.empty)


{-| Send a POST request to the given URL. You also specify how to decode the response.

    import Json.Decode (list, string)
    import Http

    hats : Task (Error (List String)) (List String)
    hats =
      post (decoder (list string) (succeed ())) "http://example.com/hat-categories.json" Http.empty

-}
post : ResponseDecoder error value -> String -> Http.Body -> Task (Error error) value
post decoder url body =
  fromJson decoder (send "POST" url body)


{-| Utility for working with Rails. Wraps Http.send, passing an Authenticity Token along with the type of request. Suitable for use with `fromJson`:

    import Dict
    import Json.Decode (list, string)
    import Json.Encode as Encode
    import Http

    hats : HatStyle -> Task (Error (List String)) (List String)
    hats style =

      let
        payload =
          Encode.object
            [ ( "style", encodeHatStyle style ) ]

        body =
          Http.string (Encode.encode 0 payload)

        success =
          list string

        failure =
          Dict.fromList [ ("style", HatStyle) ]
            |> Rails.Decode.errors
      in
        send "POST" url body
          |> fromJson (decoder success failure)
-}
send : String -> String -> Http.Body -> Task Http.RawError Http.Response
send verb url body =
  let
    csrfTokenString =
      Maybe.withDefault "" csrfToken

    csrfTokenHeaders =
      if
        (String.isEmpty csrfTokenString)
          || ((String.toUpper verb) == "GET")
      then
        []
      else
        [ "X-CSRF-Token" => csrfTokenString ]

    requestSettings =
      { verb = verb
      , headers =
          csrfTokenHeaders
            ++ [ "Content-Type" => "application/json"
               , "Accept" => "application/json, text/javascript, */*; q=0.01"
               , "X-Requested-With" => "XMLHttpRequest"
               ]
      , url = url
      , body = body
      }
  in
    Http.send Http.defaultSettings requestSettings


{-| JSON Decoders for parsing an HTTP response body.
-}
type alias ResponseDecoder error value =
  { success : Decoder value
  , failure : Decoder error
  }


{-| Returns a decoder suitable for passing to `fromJson`, which uses the same decoder for both success and failure responses.
-}
always : Decoder value -> ResponseDecoder value value
always decoder =
  ResponseDecoder decoder decoder


{-| Returns a decoder suitable for passing to `fromJson`.
-}
decoder : Decoder value -> Decoder error -> ResponseDecoder error value
decoder successDecoder failureDecoder =
  ResponseDecoder successDecoder failureDecoder


{-| Think `Http.fromJson`, but with additional effort to parse a non-20x response as JSON.

  * If the status code is in the 200 range, try to parse with the given `decoder.success`.
    * If parsing fails, return an `Http.UnexpectedPayload` wrapped in `HttpError`
  * If the status code is outside the 200 range, try to parse with the given `decoder.success`.
    * If parsing fails, return an `Http.BadResponse` wrapped in `HttpError`
-}
fromJson : ResponseDecoder error value -> Task Http.RawError Http.Response -> Task (Error error) value
fromJson decoder response =
  let
    onSuccess response str =
      case decodeString decoder.success str of
        Ok v ->
          succeed v

        Err msg ->
          fail (HttpError <| Http.UnexpectedPayload str)

    onError response str =
      case decodeString decoder.failure str of
        Ok v ->
          fail (RailsError v)

        Err msg ->
          fail (HttpError <| Http.BadResponse response.status response.statusText)

    promoteError rawError =
      case rawError of
        Http.RawTimeout ->
          HttpError Http.Timeout

        Http.RawNetworkError ->
          HttpError Http.NetworkError
  in
    mapError promoteError response
      `andThen` handleResponse onSuccess onError


type alias ResponseHandler error a =
  Http.Response -> String -> Task (Error error) a


handleResponse : ResponseHandler error a -> ResponseHandler error a -> Http.Response -> Task (Error error) a
handleResponse onSuccess onError response =
  let
    unexpectedPayloadError =
      HttpError (Http.UnexpectedPayload "Response body is a blob, expecting a string.")
  in
    case 200 <= response.status && response.status < 300 of
      True ->
        case response.value of
          Http.Text str ->
            onSuccess response str

          _ ->
            fail unexpectedPayloadError

      False ->
        case response.value of
          Http.Text str ->
            onError response str

          _ ->
            fail unexpectedPayloadError


{-| If there was a `<meta name="csrf-token">` tag in the page's `<head>` when
    elm-rails loaded, returns the value its `content` attribute had at that time.

    Rails expects this value in the `X-CSRF-Token` header for non-`GET` requests as
    a [CSRF countermeasure](http://guides.rubyonrails.org/security.html#csrf-countermeasures).
-}
csrfToken : Result String String
csrfToken =
  Native.Rails.csrfToken


(=>) : a -> a -> ( a, a )
(=>) =
  (,)
