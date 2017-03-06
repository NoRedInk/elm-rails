#!/bin/bash

set -ex

elm-make --yes
(cd examples; elm-make --yes Main.elm)
