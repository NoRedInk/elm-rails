module Main exposing (..)

import Rails
import Html exposing (div, text)


main =
    div []
        [ case Rails.csrfToken of
            Nothing ->
                text "Nothing"

            Just v ->
                text v
        ]
