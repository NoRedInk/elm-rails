module Rails exposing (Response(..), get, post, always, decoder, csrfToken, request, expectRailsJson)

{-|

## Requests
@docs Response, get, post, request

## Decoding
@docs decoder, always

## Customizing
@docs csrfToken, expectRailsJson

-}

import Http exposing (Request, Body, Expect, Header)
import Time exposing (Time)
import Json.Decode exposing (Decoder, decodeString)
import Result exposing (Result)
import String
import Native.Rails


-- Http


{-| A rails server may respond with either success or a custom error message.
-}
type Response error success
    = Error error
    | Success success


{-| Send a GET request to the given URL. You also specify how to decode the response.

    import Json.Decode (list, string)

    hats : Task (Error (List String)) (List String)
    hats =
      get (decoder (list string) (succeed ())) "http://example.com/hat-categories.json"

-}
get : String -> ResponseDecoder error success -> Request (Response error success)
get url responseDecoder =
    request
        { method = "GET"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , expect = expectRailsJson responseDecoder
        , timeout = Nothing
        , withCredentials = False
        }


{-| Send a POST request to the given URL. You also specify how to decode the response.

    import Json.Decode (list, string)
    import Http

    hats : Task (Error (List String)) (List String)
    hats =
      post (decoder (list string) (succeed ())) "http://example.com/hat-categories.json" Http.empty

-}
post : String -> Http.Body -> ResponseDecoder error success -> Request (Response error success)
post url body responseDecoder =
    request
        { method = "POST"
        , headers = []
        , url = url
        , body = body
        , expect = expectRailsJson responseDecoder
        , timeout = Nothing
        , withCredentials = False
        }


{-| Wraps `Http.request` while adding the following default headers:

* `X-CSRF-Token` - set to `csrfToken` if it's an `Ok` and this request isn't a `GET`
* `Content-Type` - `"application/json"`
* `Accept` - `"application/json, text/javascript, */*; q=0.01"`
* `X-Requested-With` - `"XMLHttpRequest"`

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
request :
    { method : String
    , headers : List Header
    , url : String
    , body : Body
    , expect : Expect (Response error success)
    , timeout : Maybe Time
    , withCredentials : Bool
    }
    -> Request (Response error success)
request options =
    let
        csrfTokenString =
            Result.withDefault "" csrfToken

        csrfTokenHeaders =
            if
                String.isEmpty csrfTokenString
                    || ((String.toUpper options.method) == "GET")
            then
                []
            else
                [ Http.header "X-CSRF-Token" csrfTokenString ]

        headers =
            List.concat
                [ defaultRequestHeaders
                , csrfTokenHeaders
                , options.headers
                ]
    in
        Http.request { options | headers = headers }


defaultRequestHeaders : List Header
defaultRequestHeaders =
    [ Http.header "Content-Type" "application/json"
    , Http.header "Accept" "application/json, text/javascript, */*; q=0.01"
    , Http.header "X-Requested-With" "XMLHttpRequest"
    ]


{-| JSON Decoders for parsing an HTTP response body.
-}
type alias ResponseDecoder error success =
    { success : Decoder success
    , failure : Decoder error
    }


{-| Returns a decoder suitable for passing to `fromJson`, which uses the same decoder for both success and failure responses.
-}
always : Decoder success -> ResponseDecoder success success
always decoder =
    ResponseDecoder decoder decoder


{-| Returns a decoder suitable for passing to `fromJson`.
-}
decoder : Decoder success -> Decoder error -> ResponseDecoder error success
decoder successDecoder failureDecoder =
    ResponseDecoder successDecoder failureDecoder


{-| If there was a `<meta name="csrf-token">` tag in the page's `<head>` when
    elm-rails loaded, returns the value its `content` attribute had at that time.

    Rails expects this value in the `X-CSRF-Token` header for non-`GET` requests as
    a [CSRF countermeasure](http://guides.rubyonrails.org/security.html#csrf-countermeasures).
-}
csrfToken : Result String String
csrfToken =
    Native.Rails.csrfToken


{-| Think `Http.fromJson`, but with additional effort to parse a non-20x response as JSON.

  * If the status code is in the 200 range, try to parse with the given `decoder.success`.
  * If the status code is outside the 200 range, try to parse with the given `decoder.failure`.
  * If either parsing fails, return an error
-}
expectRailsJson : ResponseDecoder error success -> Expect (Response error success)
expectRailsJson responseDecoder =
    let
        fromResponse : Http.Response String -> Result String (Response error success)
        fromResponse { status, body } =
            if status.code >= 200 && status.code < 300 then
                Json.Decode.decodeString responseDecoder.success body
                    |> Result.map Success
            else
                Json.Decode.decodeString responseDecoder.failure body
                    |> Result.map Error
    in
        Http.expectStringResponse fromResponse
