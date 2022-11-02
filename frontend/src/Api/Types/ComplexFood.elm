module Api.Types.ComplexFood exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Api.Types.UUID exposing (..)

import Api.Types.ComplexFoodUnit exposing (..)

type alias ComplexFood = { recipeId: UUID, amount: Float, unit: ComplexFoodUnit }


decoderComplexFood : Decode.Decoder ComplexFood
decoderComplexFood = Decode.succeed ComplexFood |> required "recipeId" decoderUUID |> required "amount" Decode.float |> required "unit" decoderComplexFoodUnit


encoderComplexFood : ComplexFood -> Encode.Value
encoderComplexFood obj = Encode.object [ ("recipeId", encoderUUID obj.recipeId), ("amount", Encode.float obj.amount), ("unit", encoderComplexFoodUnit obj.unit) ]