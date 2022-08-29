module Api.Types.NutrientUnit exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type NutrientUnit = Gram | Kilocalorie | Kilojoule | Microgram | Milligram | NiacinEquivalent


decoderNutrientUnit : Decode.Decoder NutrientUnit
decoderNutrientUnit = Decode.field "type" Decode.string |> Decode.andThen decoderNutrientUnitTpe

decoderNutrientUnitTpe : String -> Decode.Decoder NutrientUnit
decoderNutrientUnitTpe tpe =
   case tpe of
      "Gram" -> Decode.succeed Gram
      "Kilocalorie" -> Decode.succeed Kilocalorie
      "Kilojoule" -> Decode.succeed Kilojoule
      "Microgram" -> Decode.succeed Microgram
      "Milligram" -> Decode.succeed Milligram
      "NiacinEquivalent" -> Decode.succeed NiacinEquivalent
      _ -> Decode.fail ("Unexpected type for NutrientUnit: " ++ tpe)


encoderNutrientUnit : NutrientUnit -> Encode.Value
encoderNutrientUnit tpe =
   case tpe of
      Gram -> Encode.object [ ("type", Encode.string "Gram") ]
      Kilocalorie -> Encode.object [ ("type", Encode.string "Kilocalorie") ]
      Kilojoule -> Encode.object [ ("type", Encode.string "Kilojoule") ]
      Microgram -> Encode.object [ ("type", Encode.string "Microgram") ]
      Milligram -> Encode.object [ ("type", Encode.string "Milligram") ]
      NiacinEquivalent -> Encode.object [ ("type", Encode.string "NiacinEquivalent") ]