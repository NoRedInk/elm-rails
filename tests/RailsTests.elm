module RailsTests exposing (all)

import Test exposing (..)
import Expect exposing (Expectation)
import Rails
import Json.Decode
import Http
import Dict


all : Test
all =
    describe "Rails"
        [ describe "decodeErrors"
            [ test "Passes through Ok values" <|
                \() ->
                    Ok ()
                        |> Rails.decodeErrors Json.Decode.string
                        |> Expect.equal (Ok ())
            , test "Parses the body of BadStatus errors" <|
                \() ->
                    Err
                        (Http.BadStatus
                            { url = ""
                            , status = { code = 400, message = "" }
                            , headers = Dict.empty
                            , body = "\"custom error\""
                            }
                        )
                        |> Rails.decodeErrors Json.Decode.string
                        |> expectErr (.rails >> Expect.equal (Just "custom error"))
            ]
        , describe "decodeRawErrors"
            [ test "Parses the body of BadStatus errors" <|
                \() ->
                    Http.BadStatus
                        { url = ""
                        , status = { code = 400, message = "" }
                        , headers = Dict.empty
                        , body = "\"custom error\""
                        }
                        |> Rails.decodeRawErrors Json.Decode.string
                        |> .rails
                        |> Expect.equal (Just "custom error")
            ]
        ]


expectErr : (x -> Expectation) -> Result x a -> Expectation
expectErr check result =
    case result of
        Err x ->
            check x

        Ok _ ->
            Expect.fail ("Expected (Err _), but got: " ++ toString result)
