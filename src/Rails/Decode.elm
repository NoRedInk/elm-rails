module Rails.Decode exposing (ErrorList, errors)

{-| Types
@docs ErrorList


# Decoding

@docs errors

-}

import Dict
import Json.Decode as Decode exposing (Decoder, field)
import Result exposing (Result)


{-| ErrorList is a type alias for a list of `( fields, String )` pairs,
where `field` is a type we can use to reference which fields had errors.

    type Field
        = Name
        | Password

    decode : ErrorList Field

-}
type alias ErrorList field =
    List ( field, String )



-- Decoding


{-| Decodes errors passed from rails formatted like this:

`{ errors: {errorName: ["Error String"] } }`.

This function takes a Dict that is a map of all the fields you need decoded.
It should look like this:

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
        errorsDecoder : Decoder (List ( String, List String ))
        errorsDecoder =
            Decode.keyValuePairs (Decode.list Decode.string)

        finalDecoder : Decoder (ErrorList field)
        finalDecoder =
            errorsDecoder
                |> Decode.andThen (toFinalDecoder [])

        fieldDecoderFor : String -> Decoder field
        fieldDecoderFor fieldName =
            Dict.get fieldName mappings
                |> Maybe.map Decode.succeed
                |> Maybe.withDefault (Decode.fail ("Unrecognized Field: " ++ fieldName))

        toFinalDecoder :
            List ( field, String )
            -> List ( String, List String )
            -> Decoder (List ( field, String ))
        toFinalDecoder results rawErrors =
            case rawErrors of
                [] ->
                    Decode.succeed results

                ( fieldName, errors ) :: others ->
                    let
                        newResults : Result String (ErrorList field)
                        newResults =
                            Decode.decodeString (fieldDecoderFor fieldName) ("\"" ++ fieldName ++ "\"")
                                |> Result.map (tuplesFromField errors results)
                    in
                    case newResults of
                        Err err ->
                            Decode.fail err

                        Ok newResultList ->
                            toFinalDecoder newResultList others

        tuplesFromField : List String -> ErrorList field -> field -> ErrorList field
        tuplesFromField errors results field =
            errors
                |> List.map (\error -> ( field, error ))
                |> List.append results
    in
    field "errors" finalDecoder
