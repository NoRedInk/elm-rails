module Rails.Decode (errors) where

{-|

# Decoding
@docs errors

-}

import Json.Decode as Decode exposing (Decoder, (:=))
import Result exposing (Result)
import Dict exposing (Dict)


-- Decoding

{-| Decodes errors passed from rails formatted as

`{ errors: {errorName: ["Error String"] } }`.

This function takes a Dict that is a map of all the fields you need decoded. It should be formatted
nest

Dict.fromList
    [ ( "school", School )
    , ( "school.name", SchoolName )
    , ( "school.address", SchoolAddress )
    , ( "school.city", City )
    , ( "school.state", State )
    , ( "school.zip", Zip )
    , ( "school.country", Country )
    ]

-}
errors : Dict String field -> Decoder (List ( field, String ))
errors =
    errorsWithDefault failOnUnrecognized


errorsWithDefault default mappings =
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
                |> Maybe.withDefault (default fieldName)


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


failOnUnrecognized fieldName =
    Decode.fail ("Unrecognized Field: " ++ fieldName)

