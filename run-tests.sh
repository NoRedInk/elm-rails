#!/bin/bash

if [ ! -e node_modules/.bin/elm-test ]; then
    npm install elm-test
fi

set -ex

node_modules/.bin/elm-test
elm-make --yes
(cd examples; elm-make --yes Main.elm)
