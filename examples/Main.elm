module Main where

import Rails

import Graphics.Element exposing (show)

main =
    case Rails.authToken of
        Nothing -> show "nothing"
        Just v -> show v
