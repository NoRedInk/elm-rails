module Rails exposing
    ( get, post, put, patch, delete, request
    , Expect, RailsResponse(..), expectString, expectEmptyBody, expectJson, expectJsonErrors
    )

{-|


## Requests

@docs get, post, put, patch, delete, request


## Expectations

@docs Expect, RailsResponse, expectString, expectEmptyBody, expectJson, expectJsonErrors

-}

import Http exposing (Body, Header)
import Json.Decode as Decode exposing (Decoder, decodeString)



-- HTTP


{-| Send a GET request to the given URL. Specify how to decode the response.

    import Rails

    getHats : Cmd msg
    getHats =
        Rails.get
            { url = "https://example.com/hats"
            , expect = Rails.expectJson HandleGetHatsResponse hatsDecoder
            }

-}
get :
    { url : String
    , expect : Expect msg
    }
    -> Cmd msg
get { url, expect } =
    request
        { method = "GET"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , expect = expect
        , timeout = Nothing
        , tracker = Nothing
        }


{-| Send a POST request to the given URL. Specify how to decode the response.

    import Http
    import Rails

    createHat : Hat -> Cmd msg
    createHat =
        Rails.post
            { url = "https://example.com/hats"
            , body = Http.jsonBody (encodeHat hat)
            , expect = Rails.expectJson HandleNewHatResponse hatDecoder
            }

**NOTE:** Rails typically expects an `X-CSRF-Token` header for `POST` requests,
which this does not include. To have this header included automatically, add
[`csrf-xhr`](https://www.npmjs.com/package/csrf-xhr) to the page, before your
`Elm` program gets initialized.

-}
post :
    { url : String
    , body : Body
    , expect : Expect msg
    }
    -> Cmd msg
post { url, body, expect } =
    request
        { method = "POST"
        , headers = []
        , url = url
        , body = body
        , expect = expect
        , timeout = Nothing
        , tracker = Nothing
        }


{-| Send a PUT request to the given URL. Specify how to decode the response.

    import Http
    import Rails

    updateHat : Hat -> Cmd msg
    updateHat hat =
        Rails.put
            { url = "https://example.com/hats/" ++ String.fromInt hat.id
            , body = Http.jsonBody (encodeHat hat)
            , expect = Rails.expectJson HandleUpdatedHatResponse hatDecoder
            }

**NOTE:** Rails typically expects an `X-CSRF-Token` header for `PUT` requests,
which this does not include. To have this header included automatically, add
[`csrf-xhr`](https://www.npmjs.com/package/csrf-xhr) to the page, before your
`Elm` program gets initialized.

-}
put :
    { url : String
    , body : Body
    , expect : Expect msg
    }
    -> Cmd msg
put { url, body, expect } =
    request
        { method = "PUT"
        , headers = []
        , url = url
        , body = body
        , expect = expect
        , timeout = Nothing
        , tracker = Nothing
        }


{-| Send a PATCH request to the given URL. Specify how to decode the response.

    import Http
    import Json.Encode exposing (object, string)
    import Rails

    updateHatDescription : Int -> String -> Cmd msg
    updateHatDescription id description =
        Rails.patch
            { url = "https://example.com/hats/" ++ String.fromInt hat.id
            , body = Http.jsonBody (object [ ( "description", string description ) ])
            , expect = Rails.expectJson HandleUpdatedHatResponse hatDecoder
            }

**NOTE:** Rails typically expects an `X-CSRF-Token` header for `PATCH` requests,
which this does not include. To have this header included automatically, add
[`csrf-xhr`](https://www.npmjs.com/package/csrf-xhr) to the page, before your
`Elm` program gets initialized.

-}
patch :
    { url : String
    , body : Body
    , expect : Expect msg
    }
    -> Cmd msg
patch { url, body, expect } =
    request
        { method = "PATCH"
        , headers = []
        , url = url
        , body = body
        , expect = expect
        , timeout = Nothing
        , tracker = Nothing
        }


{-| Send a DELETE request to the given URL. Specify how to decode the response.

    import Http
    import Rails

    destroyHat : Hat -> Cmd msg
    destroyHat =
        Rails.delete
            { url = "https://example.com/hats/" ++ String.fromInt hat.id
            , body = Http.emptyBody
            , expect = Rails.expectEmptyBody HandleDeletedHatResponse
            }

**NOTE:** Rails typically expects an `X-CSRF-Token` header for `DELETE`
requests, which this does not include. To have this header included
automatically, add [`csrf-xhr`](https://www.npmjs.com/package/csrf-xhr) to the
page, before your `Elm` program gets initialized.

-}
delete :
    { url : String
    , body : Body
    , expect : Expect msg
    }
    -> Cmd msg
delete { url, body, expect } =
    request
        { method = "DELETE"
        , headers = []
        , url = url
        , body = body
        , expect = expect
        , timeout = Nothing
        , tracker = Nothing
        }


{-| Wraps `Http.request` while adding the following default headers:

  - `Accept`
      - for JSON: `"application/json, text/javascript, */*; q=0.01"`
      - for string: `"*/*"`
  - `X-Requested-With` - `"XMLHttpRequest"`

You can specify additional headers in the `headers` field of the configuration record.
The `delete` example above would look lik this:

    import Http
    import Rails

    destroyHat : Hat -> Cmd msg
    destroyHat =
        Rails.request
            { method = "DELETE"
            , headers = []
            , url = "https://example.com/hats/" ++ String.fromInt hat.id
            , body = Http.emptyBody
            , expect = Rails.expectEmptyBody HandleDeletedHatResponse
            , timeout = Nothing
            , tracker = Nothing
            }

**NOTE:** Rails typically expects an `X-CSRF-Token` header for requests other
than `GET`, which this does not include. One way to have this header included
automatically is to add [`csrf-xhr`](https://www.npmjs.com/package/csrf-xhr) to
the page, before your `Elm` program gets initialized.

-}
request :
    { method : String
    , headers : List Header
    , url : String
    , body : Body
    , expect : Expect msg
    , timeout : Maybe Float
    , tracker : Maybe String
    }
    -> Cmd msg
request { method, headers, url, body, expect, timeout, tracker } =
    let
        accept =
            case expect of
                Expect JSON _ ->
                    -- q indicates the preference for a content type. In this
                    -- case it means that we want any content type, only if
                    -- nothing else is possible.
                    Http.header "Accept" "application/json, text/javascript, */*; q=0.01"

                Expect Text _ ->
                    Http.header "Accept" "*/*"

        requestedWith =
            Http.header "X-Requested-With" "XMLHttpRequest"

        (Expect _ unwrappedExpect) =
            expect
    in
    Http.request
        { method = method
        , headers = accept :: requestedWith :: headers
        , url = url
        , body = body
        , expect = unwrappedExpect
        , timeout = timeout
        , tracker = tracker
        }



-- EXPECTATIONS


{-| Expect that the response body will look a certain way. Similar to
[`Http.Expect`](https://package.elm-lang.org/packages/elm/http/2.0.0/Http#Expect),
but wrapped here so we know what headers to set in requests.
-}
type Expect msg
    = Expect ContentType (Http.Expect msg)


type ContentType
    = Text
    | JSON


{-| The kinds of responses a Rails server may return.
-}
type RailsResponse error success
    = Success success
    | HttpError Http.Error
    | AppError Http.Metadata error


{-| Expect Rails to return some string data. If this will be JSON, use
[`expectJson`](#expectJson) instead!
-}
expectString : (Result Http.Error String -> msg) -> Expect msg
expectString =
    Expect Text << Http.expectString


{-| Expect Rails to return an empty body. Note that we don't actually enforce
the body is empty; we just discard it. Pairs well with [`delete`](#delete).
-}
expectEmptyBody : (Result Http.Error () -> msg) -> Expect msg
expectEmptyBody toMsg =
    Expect Text <| Http.expectString (Result.map (\_ -> ()) >> toMsg)


{-| Expect Rails to return JSON.
-}
expectJson : (Result Http.Error msg -> msg) -> Decoder msg -> Expect msg
expectJson toMsg decoder =
    Expect JSON <| Http.expectJson toMsg decoder


{-| Decode Rails-specific error information from a
[`BadStatus_`](https://package.elm-lang.org/packages/elm/http/2.0.0/Http#Response)
response (that is, a response whose status code is outside the 200 range.)

    import Dict
    import Http
    import Json.Decode exposing (at, string)
    import Json.Encode as Encode
    import Rails
    import Rails.Decode

    createHat : Hat -> Cmd Msg
    createHat hat =
        let
            errorsDecoder =
                Rails.Decode.decodeErrors (at [ "errors", "style" ] string)
        in
        Rails.post
            { url = "https://example.com/hats"
            , body = Http.jsonBody (encodeHat hat)
            , expect = Rails.expectJsonErrors HandleNewHatResponse errorsDecoder hatDecoder
            }

-}
expectJsonErrors : (RailsResponse error success -> msg) -> Decoder error -> Decoder success -> Expect msg
expectJsonErrors toMsg errorDecoder successDecoder =
    let
        {- We want to eventually return a `RailsResponse` to reduce the level of
           unwrapping the caller needs to do, but `expectStringResponse`
           requires us to return a `Result`. We'll just unwrap one level outside
           this function so we don't have to deal with, e.g. `Result Never
           (RailsResponse error success)`
        -}
        toResult : Http.Response String -> Result (RailsResponse error never) success
        toResult response =
            case response of
                Http.BadUrl_ url ->
                    Err (HttpError (Http.BadUrl url))

                Http.Timeout_ ->
                    Err (HttpError Http.Timeout)

                Http.NetworkError_ ->
                    Err (HttpError Http.NetworkError)

                Http.BadStatus_ metadata body ->
                    case Decode.decodeString errorDecoder body of
                        Ok decoded ->
                            Err (AppError metadata decoded)

                        Err err ->
                            Err (HttpError (Http.BadBody ("Failed to decode error: " ++ Decode.errorToString err)))

                Http.GoodStatus_ metadata body ->
                    case Decode.decodeString successDecoder body of
                        Ok decoded ->
                            Ok decoded

                        Err err ->
                            Err (HttpError (Http.BadBody ("Failed to decode result: " ++ Decode.errorToString err)))

        toRailsResponse : Result (RailsResponse error success) success -> RailsResponse error success
        toRailsResponse result =
            case result of
                Ok success ->
                    Success success

                Err whatever ->
                    whatever
    in
    Expect JSON <| Http.expectStringResponse (toRailsResponse >> toMsg) toResult
