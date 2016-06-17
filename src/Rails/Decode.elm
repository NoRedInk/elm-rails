module Rails.Decode exposing (errors, ErrorList)

{-|

Types
@docs ErrorList

# Decoding
@docs errors

-}

import Json.Decode as Decode exposing (Decoder, (:=))
import Result exposing (Result)
import Dict

{-| ErrorList is a type alias for
a list of fields to String, where `field` is expected to be a type for matching
errors to
```

type Field = Name | Password

decode : ErrorList Field

```
-}
type alias ErrorList field =
    List (field, String)

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
errors : Dict.Dict String field -> Decoder (ErrorList field)
errors mappings =
    let
        errorsDecoder : Decoder (List (String, List String))
        errorsDecoder =
            Decode.keyValuePairs (Decode.list Decode.string)

        --finalDecoder : Decoder (ErrorList field)
        finalDecoder =
            Decode.customDecoder errorsDecoder (toFinalDecoder [])

        --fieldDecoderFor : String -> Decoder field
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
                        --newResults : Result String (ErrorList field)
                        newResults =
                            Decode.decodeString (fieldDecoderFor fieldName) ("\"" ++ fieldName ++ "\"")
                                |> Result.map (tuplesFromField errors results)

                    in
                        case newResults of
                            Err _ ->
                                newResults

                            Ok newResultList ->
                                toFinalDecoder newResultList others

        --tuplesFromField : List String -> (ErrorList field) -> field -> (ErrorList field)
        tuplesFromField errors results field =
            errors
                |> List.map (\error -> (field, error))
                |> List.append results

    in
        "errors" := finalDecoder
