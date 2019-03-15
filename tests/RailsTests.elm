module RailsTests exposing (all)

import Dict
import Expect exposing (Expectation)
import Http
import Json.Decode
import Rails
import Test exposing (..)


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
                    Err (Http.BadStatus 400)
                        |> Rails.decodeErrors Json.Decode.string
                        |> expectErr (.rails >> Expect.equal (Just "custom error"))
            ]
        , describe "decodeRawErrors"
            [ test "Parses the body of BadStatus errors" <|
                \() ->
                    Http.BadStatus 400
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
            Expect.fail ("Expected (Err _), but got: " ++ Debug.toString result)
