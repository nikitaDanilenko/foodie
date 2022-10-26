module Api.Types.ComplexFoodUnit exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode


type ComplexFoodUnit
    = G
    | ML



-- todo: Consider a more automatic approach


decoderComplexFoodUnit : Decode.Decoder ComplexFoodUnit
decoderComplexFoodUnit =
    Decode.string |> Decode.andThen decoderComplexFoodUnitByString


decoderComplexFoodUnitByString : String -> Decode.Decoder ComplexFoodUnit
decoderComplexFoodUnitByString string =
    case string of
        "G" ->
            Decode.succeed G

        "ML" ->
            Decode.succeed ML

        _ ->
            Decode.fail ("Unexpected type for ComplexFoodUnit: " ++ string)


encoderComplexFoodUnit : ComplexFoodUnit -> Encode.Value
encoderComplexFoodUnit =
    toString >> Encode.string


toString : ComplexFoodUnit -> String
toString complexFoodUnit =
    case complexFoodUnit of
        G ->
            "G"

        ML ->
            "ML"


toPrettyString : ComplexFoodUnit -> String
toPrettyString =
    toString >> String.toLower


fromString : String -> Maybe ComplexFoodUnit
fromString =
    String.toUpper
        >> (\s -> String.concat [ "\"", s, "\"" ])
        >> Decode.decodeString decoderComplexFoodUnit
        >> Result.toMaybe
