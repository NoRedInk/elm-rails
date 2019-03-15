module Main exposing (main)

import Browser
import Dict exposing (Dict)
import Html exposing (Html)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Rails


type alias Model =
    Dict String TestResult


type alias TestResult =
    Maybe (Result String ())


type Msg
    = Completed String (Result String ())


complete : String -> Result x a -> Msg
complete name result =
    case result of
        Ok _ ->
            Completed name (Ok ())

        Err err ->
            Completed name (Err (Debug.toString err))


testCases : List ( String, String -> Cmd Msg )
testCases =
    [ ( "get"
      , \name ->
            Rails.get
                { url = "https://httpbin.org/get"
                , expect = Rails.expectEmptyBody (complete name)
                }
      )
    , ( "post"
      , \name ->
            Rails.post
                { url = "https://httpbin.org/post"
                , body = Http.emptyBody
                , expect = Rails.expectEmptyBody (complete name)
                }
      )
    , ( "put"
      , \name ->
            Rails.put
                { url = "https://httpbin.org/put"
                , body = Http.emptyBody
                , expect = Rails.expectEmptyBody (complete name)
                }
      )
    , ( "patch"
      , \name ->
            Rails.patch
                { url = "https://httpbin.org/patch"
                , body = Http.emptyBody
                , expect = Rails.expectEmptyBody (complete name)
                }
      )
    , ( "delete"
      , \name ->
            Rails.delete
                { url = "https://httpbin.org/delete"
                , body = Http.emptyBody
                , expect = Rails.expectEmptyBody (complete name)
                }
      )
    , ( "request with empty body"
      , \name ->
            Rails.request
                { method = "POST"
                , headers = []
                , url = "https://httpbin.org/post"
                , body = Http.emptyBody
                , expect = Rails.expectEmptyBody (complete name)
                , timeout = Nothing
                , tracker = Nothing
                }
      )
    , ( "request with JSON body"
      , \name ->
            let
                data =
                    "Hello, World!"
            in
            Rails.request
                { method = "POST"
                , headers = []
                , url = "https://httpbin.org/post"
                , body = Http.jsonBody (Encode.string data)
                , expect =
                    Rails.expectJson (complete name)
                        (Decode.andThen
                            (\out ->
                                if out == data then
                                    Decode.succeed ()

                                else
                                    Decode.fail ("data was \"" ++ out ++ "\", not \"" ++ data ++ "\"")
                            )
                            (Decode.field "json" Decode.string)
                        )
                , timeout = Nothing
                , tracker = Nothing
                }
      )
    , ( "request with string body"
      , \name ->
            let
                data =
                    "Hello, World!"
            in
            Rails.request
                { method = "POST"
                , headers = []
                , url = "https://httpbin.org/anything"
                , body = Http.stringBody "text/plain" data
                , expect =
                    Rails.expectJson (complete name)
                        (Decode.andThen
                            (\out ->
                                if out == data then
                                    Decode.succeed ()

                                else
                                    Decode.fail ("data was \"" ++ out ++ "\", not \"" ++ data ++ "\"")
                            )
                            (Decode.field "data" Decode.string)
                        )
                , timeout = Nothing
                , tracker = Nothing
                }
      )
    ]


init : a -> ( Model, Cmd Msg )
init _ =
    ( testCases
        |> List.map (Tuple.mapSecond (\_ -> Nothing))
        |> Dict.fromList
    , testCases
        |> List.map (\( name, test ) -> test name)
        |> Cmd.batch
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update (Completed name result) model =
    ( Dict.insert name (Just result) model
    , Cmd.none
    )


view : Model -> Browser.Document Msg
view model =
    { title = "elm-rails test suite"
    , body =
        model
            |> Dict.toList
            |> List.map
                (\( name, outcome ) ->
                    Html.section []
                        [ Html.p [] [ Html.text name ]
                        , Html.p []
                            [ case outcome of
                                Nothing ->
                                    Html.text "PENDING"

                                Just (Ok _) ->
                                    Html.text "PASS"

                                Just (Err why) ->
                                    Html.text ("Failure: " ++ why)
                            ]
                        ]
                )
    }


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }
