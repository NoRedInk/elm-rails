module Rails exposing
    ( get, post, put, patch, delete, request
    , Expect, RailsError(..), expectJson, expectJsonErrors
    )

{-|


## Requests

@docs get, post, put, patch, delete, request


## Expectations

@docs Expect, RailsError, expectJson, expectJsonErrors

-}

import Http exposing (Body, Header)
import Json.Decode as Decode exposing (Decoder, decodeString)



-- HTTP


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
    import Json.Decode exposing (list, string, succeed)
    import Rails

    hats : Cmd msg
    hats =
        list hatDecoder
            |> Rails.post "http://example.com/hat-categories/new" Http.emptyBody
            |> Http.send HandleResponse

**NOTE:** Rails typically expects an `X-CSRF-Token` header for `POST`
requests, which this does not include. To have this header included
automatically, add [`csrf-xhr`](https://www.npmjs.com/package/csrf-xhr)
to the page, before your `Elm` program gets initialized.

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
    import Json.Decode exposing (list, string, succeed)
    import Rails

    hats : Cmd msg
    hats =
        list hatDecoder
            |> Rails.put "http://example.com/hat-categories/5" revisedHatData
            |> Http.send HandleResponse

**NOTE:** Rails typically expects an `X-CSRF-Token` header for `PUT`
requests, which this does not include. To have this header included
automatically, add [`csrf-xhr`](https://www.npmjs.com/package/csrf-xhr)
to the page, before your `Elm` program gets initialized.

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
    import Json.Decode exposing (list, string, succeed)
    import Rails

    hats : Cmd msg
    hats =
        list hatDecoder
            |> Rails.patch "http://example.com/hat-categories/5" revisedHatData
            |> Http.send HandleResponse

**NOTE:** Rails typically expects an `X-CSRF-Token` header for `PATCH`
requests, which this does not include. To have this header included
automatically, add [`csrf-xhr`](https://www.npmjs.com/package/csrf-xhr)
to the page, before your `Elm` program gets initialized.

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
    import Json.Decode exposing (list, string, succeed)
    import Rails

    hats : Cmd msg
    hats =
        list hatDecoder
            |> Rails.delete "http://example.com/hat-categories/5" Http.emptyBody
            |> Http.send HandleResponse

**NOTE:** Rails typically expects an `X-CSRF-Token` header for `DELETE`
requests, which this does not include. To have this header included
automatically, add [`csrf-xhr`](https://www.npmjs.com/package/csrf-xhr)
to the page, before your `Elm` program gets initialized.

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

**NOTE:** Rails typically expects an `X-CSRF-Token` header for requests other
than `GET`, which this does not include. One way to have this header included
automatically is to add [`csrf-xhr`](https://www.npmjs.com/package/csrf-xhr)
to the page, before your `Elm` program gets initialized.

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
                ExpectJson _ ->
                    Http.header "Accept" "application/json, text/javascript, */*; q=0.01"

        requestedWith =
            Http.header "X-Requested-With" "XMLHttpRequest"

        unwrappedExpect =
            case expect of
                ExpectJson inner ->
                    inner
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


type Expect msg
    = ExpectJson (Http.Expect msg)


{-| The kinds of errors a Rails server may return.
-}
type RailsError error success
    = Success success
    | HttpError Http.Error
    | AppError Http.Metadata error


{-| TODO: docs
-}
expectJson : (Result Http.Error msg -> msg) -> Decoder msg -> Expect msg
expectJson toMsg decoder =
    ExpectJson <| Http.expectJson toMsg decoder


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
expectJsonErrors : (RailsError error success -> msg) -> Decoder error -> Decoder success -> Expect msg
expectJsonErrors toMsg errorDecoder successDecoder =
    let
        {- We want to eventually return a `RailsError` to reduce the level of
           unwrapping the caller needs to do, but `expectStringResponse`
           requires us to return a `Result`. We'll just unwrap one level outside
           this function so we don't have to deal with, e.g. `Result Never
           (RailsError error success)`
        -}
        toResult : Http.Response String -> Result (RailsError error never) success
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

        toRailsError : Result (RailsError error success) success -> RailsError error success
        toRailsError result =
            case result of
                Ok success ->
                    Success success

                Err whatever ->
                    whatever
    in
    ExpectJson <| Http.expectStringResponse (toRailsError >> toMsg) toResult
