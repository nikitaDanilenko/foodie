module Api.Types.NutrientUnit exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode


type NutrientUnit
    = Gram
    | IU
    | Kilocalorie
    | Kilojoule
    | Microgram
    | Milligram
    | NiacinEquivalent


decoderNutrientUnit : Decode.Decoder NutrientUnit
decoderNutrientUnit =
    Decode.string |> Decode.andThen decoderNutrientUnitByString



-- todo: Consider a more automatic approach


decoderNutrientUnitByString : String -> Decode.Decoder NutrientUnit
decoderNutrientUnitByString tpe =
    case tpe of
        "g" ->
            Decode.succeed Gram

        "IU" ->
            Decode.succeed IU

        "kCal" ->
            Decode.succeed Kilocalorie

        "kJ" ->
            Decode.succeed Kilojoule

        "µg" ->
            Decode.succeed Microgram

        "mg" ->
            Decode.succeed Milligram

        "NE" ->
            Decode.succeed NiacinEquivalent

        _ ->
            Decode.fail ("Unexpected type for NutrientUnit: " ++ tpe)


encoderNutrientUnit : NutrientUnit -> Encode.Value
encoderNutrientUnit =
    toString >> Encode.string


toString : NutrientUnit -> String
toString nutrientUnit =
    case nutrientUnit of
        Gram ->
            "g"

        IU ->
            "IU"

        Kilocalorie ->
            "kCal"

        Kilojoule ->
            "kJ"

        Microgram ->
            "µg"

        Milligram ->
            "mg"

        NiacinEquivalent ->
            "NE"
