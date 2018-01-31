module Rails exposing (Error, decodeErrors, decodeRawErrors, delete, get, patch, post, put, request)

{-|


## Requests

@docs Error, get, post, put, patch, delete, decodeErrors, decodeRawErrors, request

-}

import Http exposing (Body, Expect, Header, Request, Response)
import Json.Decode exposing (Decoder, decodeString)
import Result exposing (Result)
import Time exposing (Time)


-- Http


{-| The kinds of errors a Rails server may return.
-}
type alias Error error =
    { http : Http.Error
    , rails : Maybe error
    }


{-| Send a GET request to the given URL. Specify how to decode the response.

    import Http
    import Json.Decode exposing (list, string, succeed)
    import Rails

    getHats : Cmd msg
    getHats =
        list hatDecoder
            |> Rails.get "http://example.com/hat-categories.json"
            |> Http.send HandleGetHatsResponse

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

    import Http
    import Json.Decode exposing (list, string, succeed)
    import Rails

    hats : Cmd msg
    hats =
        list hatDecoder
            |> Rails.post "http://example.com/hat-categories/new" Http.emptyBody
            |> Http.send HandleResponse

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

    import Http
    import Json.Decode exposing (list, string, succeed)
    import Rails

    hats : Cmd msg
    hats =
        list hatDecoder
            |> Rails.put "http://example.com/hat-categories/5" revisedHatData
            |> Http.send HandleResponse

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


{-| Send a PATCH request to the given URL. Specify how to decode the response.

    import Http
    import Json.Decode exposing (list, string, succeed)
    import Rails

    hats : Cmd msg
    hats =
        list hatDecoder
            |> Rails.patch "http://example.com/hat-categories/5" revisedHatData
            |> Http.send HandleResponse

-}
patch : String -> Http.Body -> Decoder val -> Request val
patch url body decoder =
    request
        { method = "PATCH"
        , headers = []
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }


{-| Send a DELETE request to the given URL. Specify how to decode the response.

    import Http
    import Json.Decode exposing (list, string, succeed)
    import Rails

    hats : Cmd msg
    hats =
        list hatDecoder
            |> Rails.delete "http://example.com/hat-categories/5" Http.emptyBody
            |> Http.send HandleResponse

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

  - `Content-Type` - `"application/json"`
  - `Accept` - `"application/json, text/javascript, */*; q=0.01"`
  - `X-Requested-With` - `"XMLHttpRequest"`

You can specify additional headers in the `headers` field of the configuration record.

    import Dict
    import Http
    import Json.Decode exposing (list, string)
    import Json.Encode as Encode
    import Rails
    import Rails.Decode

    hatRequest : HatStyle -> Request (Result (ErrorList Field) Hat)
    hatRequest style =
        let
            body =
                [ ( "style", encodeHatStyle style ) ]
                    |> Encode.object
                    |> Http.jsonBody
        in
        Rails.request
            { method = "POST"
            , headers = []
            , url = url
            , body = body
            , expect = Http.expectJson (list string)
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
        headers =
            List.concat
                [ defaultRequestHeaders
                , options.headers
                ]
    in
    Http.request { options | headers = headers }


defaultRequestHeaders : List Header
defaultRequestHeaders =
    [ Http.header "Accept" "application/json, text/javascript, */*; q=0.01"
    , Http.header "X-Requested-With" "XMLHttpRequest"
    ]


{-| Decode Rails-specific error information from a [`BadStatus`](http://package.elm-lang.org/packages/elm-lang/http/latest/Http#Error)
response. (That is, a response whose status code is outside the 200 range.)

This is intended to be used with [`Http.send`](http://package.elm-lang.org/packages/elm-lang/http/1.0.0/Http#send)
like so:

    import Dict
    import Http
    import Json.Decode exposing (at, list, string)
    import Json.Encode as Encode
    import Rails
    import Rails.Decode

    requestHats : HatStyle -> Cmd Msg
    requestHats style =
        let
            body =
                [ ( "style", encodeHatStyle style ) ]
                    |> Encode.object
                    |> Http.jsonBody

            getErrors =
                at [ "errors", "style" ] string
                    |> Rails.decodeErrors
        in
        list string
            |> Rails.post url body
            |> Http.send (getErrors >> HandleResponse)

-}
decodeErrors : Decoder railsError -> Result Http.Error success -> Result (Error railsError) success
decodeErrors errorDecoder result =
    Result.mapError (decodeRawErrors errorDecoder) result


{-| Decode Rails-specific error information from a [`BadStatus`](http://package.elm-lang.org/packages/elm-lang/http/latest/Http#Error)
response. (That is, a response whose status code is outside the 200 range.)

See also, `decodeErrors`.

-}
decodeRawErrors : Decoder railsError -> Http.Error -> Error railsError
decodeRawErrors errorDecoder httpError =
    case httpError of
        Http.BadStatus { body } ->
            { http = httpError
            , rails =
                Json.Decode.decodeString errorDecoder body
                    |> Result.toMaybe
            }

        _ ->
            { http = httpError
            , rails = Nothing
            }
