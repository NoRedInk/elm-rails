module Rails (send, authToken) where

{-|

# Http
@docs send

# Tokens
@docs authToken

-}

import Http
import Task exposing (Task)
import Json.Decode exposing (Decoder)

import Native.Rails


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

    in
        Http.send Http.defaultSettings requestSettings
            |> Http.fromJson decoder

{-| get the rails authToken from the meta tag
returns nothing if the tag doesn't exist
-}
authToken : Maybe String
authToken =
    let
        auth = Native.Rails.authToken
    in
        if auth == "" then Nothing
        else Just auth


(=>) = (,)

