module Rails (send) where

{-|

# Http
@docs send

-}

import Http exposing (Value(..))
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
            , headers = ["X-CSRF-Token" => authToken
                        , "Content-Type" => "application/json"
                        , "Accept" => "application/json, text/javascript, */*; q=0.01"
                        , "X-Requested-With" => "XMLHttpRequest"
                        ]
            , url = url
            , body = body
            }

        emptyBodyToNull response =
            -- Translate an empty body into "null" for JSON parsing
            if response.value == Text "" then
                { response | value <- Text "null" }
            else
                response
    in
        Http.send Http.defaultSettings requestSettings
            |> Task.map emptyBodyToNull
            |> Http.fromJson decoder

(=>) = (,)
