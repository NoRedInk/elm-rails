module Rails exposing (Error, get, post, put, delete, send, csrfToken, request)

{-|

## Requests
@docs Error, get, post, put, delete, send, request

## Customizing
@docs csrfToken

-}

import Http exposing (Request, Response, Body, Expect, Header)
import Time exposing (Time)
import Json.Decode exposing (Decoder, decodeString)
import Result exposing (Result)
import String
import Native.Rails


-- Http


{-| The kinds of errors a Rails server may return.
-}
type alias Error error =
    { http : Http.Error
    , rails : Maybe error
    }


{-| Send an HTTP request to Rails. This uses [`request`](#request) under the
hood, which means that a CSRF token will automatically be passed, among
other things.

The given decoder will be used to decode Rails-specific error information if the
response has a status code outside the 200 range.

    import Dict
    import Json.Decode exposing (list, string)
    import Json.Encode as Encode
    import Http
    import Rails.Decode
    import Rails


    requestHats : HatStyle -> Cmd Msg
    requestHats style =
        let
            body =
                [ ( "style", encodeHatStyle style ) ]
                    |> Encode.object
                    |> Http.jsonBody

            success =
                list string

            failure =
                Dict.fromList [ ( "style", HatStyle ) ]
                    |> Rails.Decode.errors
        in
            Rails.decoder success failure
                |> Rails.post url body
                |> Rails.send HandleResponse
-}
send : Decoder error -> (Result (Error error) success -> msg) -> Request success -> Cmd msg
send errorDecoder toMsg req =
    let
        newToMsg result =
            toMsg <|
                case result of
                    Err ((Http.BadStatus { body }) as httpError) ->
                        Err
                            { http = httpError
                            , rails =
                                Json.Decode.decodeString errorDecoder body
                                    |> Result.toMaybe
                            }

                    Err httpError ->
                        Err
                            { http = httpError
                            , rails = Nothing
                            }

                    Ok success ->
                        Ok success
    in
        Http.send newToMsg req


{-| Send a GET request to the given URL. Specify how to decode the response.

    import Json.Decode exposing (list, string, succeed)
    import Http
    import Rails


    getHats : Cmd msg
    getHats =
        list hatDecoder
            |> Rails.get "http://example.com/hat-categories.json"
            |> Rails.send (list string) HandleGetHatsResponse
-}
get : String -> Decoder val -> Request val
get url decoder =
    request
        { method = "GET"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }


{-| Send a POST request to the given URL. Specify how to decode the response.

    import Json.Decode exposing (list, string, succeed)
    import Http
    import Rails


    hats : Cmd msg
    hats =
        list hatDecoder
            |> Rails.post "http://example.com/hat-categories/new" Http.emptyBody
            |> Rails.send (list string) HandleResponse

-}
post : String -> Http.Body -> Decoder val -> Request val
post url body decoder =
    request
        { method = "POST"
        , headers = []
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }


{-| Send a PUT request to the given URL. Specify how to decode the response.

    import Json.Decode exposing (list, string, succeed)
    import Http
    import Rails


    hats : Cmd msg
    hats =
        list hatDecoder
            |> Rails.put "http://example.com/hat-categories/5" revisedHatData
            |> Rails.send (list string) HandleResponse

-}
put : String -> Http.Body -> Decoder val -> Request val
put url body decoder =
    request
        { method = "PUT"
        , headers = []
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }


{-| Send a DELETE request to the given URL. Specify how to decode the response.

    import Json.Decode exposing (list, string, succeed)
    import Http
    import Rails


    hats : Cmd msg
    hats =
        list hatDecoder
            |> Rails.delete "http://example.com/hat-categories/5" Http.emptyBody
            |> Rails.send (list string) HandleResponse

-}
delete : String -> Http.Body -> Decoder val -> Request val
delete url body decoder =
    request
        { method = "DELETE"
        , headers = []
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }


{-| Wraps `Http.request` while adding the following default headers:

* `X-CSRF-Token` - set to `csrfToken` if it's an `Ok` and this request isn't a `GET`
* `Content-Type` - `"application/json"`
* `Accept` - `"application/json, text/javascript, */*; q=0.01"`
* `X-Requested-With` - `"XMLHttpRequest"`

You can specify additional headers in the `headers` field of the configuration record.

    import Dict
    import Json.Decode exposing (list, string)
    import Json.Encode as Encode
    import Http
    import Rails.Decode
    import Rails


    hatRequest : HatStyle -> Request (Result (ErrorList Field) Hat)
    hatRequest style =
        let
            body =
                [ ( "style", encodeHatStyle style ) ]
                    |> Encode.object
                    |> Http.jsonBody

            success =
                list string

            failure =
                Dict.fromList [ ( "style", HatStyle ) ]
                    |> Rails.Decode.errors
        in
            Rails.request
                { method = "POST"
                , headers = []
                , url = url
                , body = body
                , expect = Http.expectJson (Rails.decoder success failure)
                , timeout = Nothing
                , withCredentials = False
                }
-}
request :
    { method : String
    , headers : List Header
    , url : String
    , body : Body
    , expect : Expect a
    , timeout : Maybe Time
    , withCredentials : Bool
    }
    -> Request a
request options =
    let
        csrfTokenHeaders =
            if (String.toUpper options.method) == "GET" then
                []
            else
                case csrfToken of
                    Err _ ->
                        []

                    Ok csrfTokenString ->
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
    [ Http.header "Accept" "application/json, text/javascript, */*; q=0.01"
    , Http.header "X-Requested-With" "XMLHttpRequest"
    ]


{-| If there was a `<meta name="csrf-token">` tag in the page's `<head>` when
    elm-rails loaded, returns the value its `content` attribute had at that time.

    Rails expects this value in the `X-CSRF-Token` header for non-`GET` requests as
    a [CSRF countermeasure](http://guides.rubyonrails.org/security.html#csrf-countermeasures).
-}
csrfToken : Result String String
csrfToken =
    Native.Rails.csrfToken
