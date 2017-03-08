module Tests exposing (..)

import Test exposing (..)
import RailsTests


all : Test
all =
    describe "elm-rails"
        [ RailsTests.all
        ]
