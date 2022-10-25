module Api.Types.ComplexIngredient exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Api.Types.UUID exposing (..)

type alias ComplexIngredient = { complexFoodId: UUID, factor: Float }


decoderComplexIngredient : Decode.Decoder ComplexIngredient
decoderComplexIngredient = Decode.succeed ComplexIngredient |> required "complexFoodId" decoderUUID |> required "factor" Decode.float


encoderComplexIngredient : ComplexIngredient -> Encode.Value
encoderComplexIngredient obj = Encode.object [ ("complexFoodId", encoderUUID obj.complexFoodId), ("factor", Encode.float obj.factor) ]