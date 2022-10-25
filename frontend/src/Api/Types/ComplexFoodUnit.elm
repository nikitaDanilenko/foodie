module Api.Types.ComplexFoodUnit exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type ComplexFoodUnit = G | ML


decoderComplexFoodUnit : Decode.Decoder ComplexFoodUnit
decoderComplexFoodUnit = Decode.field "type" Decode.string |> Decode.andThen decoderComplexFoodUnitTpe

decoderComplexFoodUnitTpe : String -> Decode.Decoder ComplexFoodUnit
decoderComplexFoodUnitTpe tpe =
   case tpe of
      "G" -> Decode.succeed G
      "ML" -> Decode.succeed ML
      _ -> Decode.fail ("Unexpected type for ComplexFoodUnit: " ++ tpe)


encoderComplexFoodUnit : ComplexFoodUnit -> Encode.Value
encoderComplexFoodUnit tpe =
   case tpe of
      G -> Encode.object [ ("type", Encode.string "G") ]
      ML -> Encode.object [ ("type", Encode.string "ML") ]