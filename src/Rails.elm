module Rails (Error(..), send, sendRaw, fromJson, always, decoder) where

{-|

# Http
@docs Error, send, sendRaw, fromJson, always, decoder

-}

import Http
import Task exposing (Task, succeed, fail, mapError, andThen)
import Json.Decode exposing (Decoder, decodeString)


-- Http


{-| The kinds of errors a Rails server may return.
-}
type Error error
    = HttpError Http.Error
    | RailsError error


{-| Utility for working with Rails. Wraps Http.send passing an Authenticity Token
along with the type of request and a way to decode results.

-}
send : String -> Decoder value -> String -> String -> Http.Body -> Task (Error value) value
send authToken decoder verb url body =
    sendRaw authToken verb url body
    |> fromJson (always decoder)


{-| Utility for working with Rails. Wraps Http.send passing an Authenticity Token along with the type of request. Suitable for use with `fromJson`:

    let
        success =
            Json.Decode.list Json.Decode.string

        failure =
            Dict.fromList [ ("hat_kind", HatKind) ]
                |> Rails.Decode.errors
    in
        Rails.sendRaw authToken "POST" url body
            |> Rails.fromJson (Rails.decoder success failure)
-}
sendRaw : String -> String -> String -> Http.Body -> Task Http.RawError Http.Response
sendRaw authToken verb url body =
    let
        requestSettings =
            { verb = verb
            , headers = [ "X-CSRF-Token" => authToken
                        , "Content-Type" => "application/json"
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
              Ok v -> succeed v
              Err msg -> fail (HttpError <| Http.UnexpectedPayload str)

        onError response str =
            case decodeString decoder.failure str of
              Ok v -> fail (RailsError v)
              Err msg -> fail (HttpError <| Http.BadResponse response.status response.statusText)

        promoteError rawError =
            case rawError of
              Http.RawTimeout -> HttpError Http.Timeout
              Http.RawNetworkError -> HttpError Http.NetworkError
    in
        mapError promoteError response
            `andThen` handleResponse onSuccess onError


type alias ResponseHandler error a =
    Http.Response -> String -> Task (Error error) a


handleResponse : (ResponseHandler error a) -> (ResponseHandler error a) -> Http.Response -> Task (Error error) a
handleResponse onSuccess onError response =
    let
        unexpectedPayloadError =
            HttpError (Http.UnexpectedPayload "Response body is a blob, expecting a string.")
    in
        case 200 <= response.status && response.status < 300 of
          True ->
              case response.value of
                Http.Text str -> onSuccess response str
                _ -> fail unexpectedPayloadError

          False ->
              case response.value of
                Http.Text str -> onError response str
                _ -> fail unexpectedPayloadError


(=>) = (,)
