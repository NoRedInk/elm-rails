module Rails.Decode (errors) where

{-|

# Decoding
@docs errors

-}

import Json.Decode as Decode exposing (Decoder, (:=))
import Result exposing (Result)
import Dict


-- Decoding

{-| Function for creating a Decoder that decodes errors formatted by rails. It is
expecting JSON formatted as:

`{ errors: {errorName: ["Error String"] } }`.

To create the decoder, pass a dict mapping your Strings to Fields that mimic
the expected nesting, eg.

```
mappings =
    Dict.fromList
        [ ( "school", School )
        , ( "school.name", SchoolName )
        , ( "school.address", SchoolAddress )
        , ( "school.city", City )
        , ( "school.state", State )
        , ( "school.zip", Zip )
        , ( "school.country", Country )
        ]

railsErrorsDecoder =
    Rails.Decode.errors mappings
```

-}
errors mappings =
    let
        errorsDecoder : Decoder (List (String, List String))
        errorsDecoder =
            Decode.keyValuePairs (Decode.list Decode.string)

        finalDecoder : Decoder (List (field, String))
        finalDecoder =
            Decode.customDecoder errorsDecoder (toFinalDecoder [])

        fieldDecoderFor : String -> Decoder field
        fieldDecoderFor fieldName =
            Dict.get fieldName mappings
                |> Maybe.map Decode.succeed
                |> Maybe.withDefault (Decode.fail ("Unrecognized Field: " ++ fieldName))


        -- toFinalDecoder : List (field, String) -> List (String, (List String)) -> Result String (List (field, String))
        toFinalDecoder results rawErrors =
            case rawErrors of
                [] ->
                    Ok results

                (fieldName, errors) :: others ->
                    let
                        newResults : Result String (List (field, String))
                        newResults =
                            Decode.decodeString (fieldDecoderFor fieldName) ("\"" ++ fieldName ++ "\"")
                                |> Result.map (tuplesFromField errors results)

                    in
                        case newResults of
                            Err _ ->
                                newResults

                            Ok newResultList ->
                                toFinalDecoder newResultList others

        tuplesFromField : List String -> List (field, String) -> field -> List (field, String)
        tuplesFromField errors results field =
            errors
                |> List.map (\error -> (field, error))
                |> List.append results

    in
        "errors" := finalDecoder
