module Main exposing (..)

import Rails
import Html exposing (div, text, Html)


main : Html msg
main =
    div []
        [ case Rails.csrfToken of
            Err err ->
                text ("csrfToken error: " ++ err)

            Ok v ->
                text v
        ]
