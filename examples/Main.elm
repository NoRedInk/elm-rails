module Main where

import Rails

import Graphics.Element exposing (show)

main =
    case Rails.csrfToken of
        Nothing -> show "Nothing"
        Just v -> show v
        _ -> show Rails.csrfToken
