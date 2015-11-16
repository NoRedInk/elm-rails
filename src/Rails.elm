module Rails (send) where

{-|

# Http
@docs send

-}

import Http
import Task exposing (Task)
import Json.Decode exposing (Decoder)

-- Http

{-| Utility for working with rails. Wraps Http.send passing an Authenticity Token
along with the type of request and a way to decode results.

-}
send : String -> Decoder value -> String -> String -> Http.Body -> Task Http.Error value
send authToken decoder verb url body =
    let
        requestSettings =
            { verb = verb
            , headers = [ "X-CSRF-Token" => authToken
                        , "Content-Type" => "application/json"
                        , "Accept" => "application/json, text/javascript, */*; q=0.01"
                        , "X-Requested-With" => "XMLHttpRequest"
                        ]
            , url = url
            , body = body
            }

    in
        Http.send Http.defaultSettings requestSettings
            |> Http.fromJson decoder

(=>) = (,)
