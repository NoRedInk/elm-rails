module Rails (send, authToken) where

{-|

# Http
@docs send

# Tokens
@docs csrfToken

-}

import Http
import Task exposing (Task)
import Json.Decode exposing (Decoder)
import Maybe
import Native.Rails


-- Http

{-| Utility for working with rails. Wraps Http.send passing an Authenticity Token
along with the type of request and a way to decode results.

-}
send : String -> Decoder value -> String -> String -> Http.Body -> Task Http.Error value
send csrfToken decoder verb url body =
    let
        requestSettings =
            { verb = verb
            , headers = ["X-CSRF-Token" => csrfToken
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

{-| If there was a `<meta name="csrf-token">` tag in the page's `<head>` when
elm-rails loaded, returns the value its `content` attribute had at that time.

Rails expects this value in the `X-CSRF-Token` header for non-`GET` requests as
a [CSRF countermeasure](http://guides.rubyonrails.org/security.html#csrf-countermeasures).
-}
csrfToken : Maybe String
csrfToken = Native.Rails.csrfToken


(=>) = (,)

