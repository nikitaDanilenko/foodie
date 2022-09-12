module Api.Types.MealEntry exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Api.Types.UUID exposing (..)

type alias MealEntry = { id: UUID, recipeId: UUID, numberOfServings: Float }


decoderMealEntry : Decode.Decoder MealEntry
decoderMealEntry = Decode.succeed MealEntry |> required "id" decoderUUID |> required "recipeId" decoderUUID |> required "numberOfServings" Decode.float


encoderMealEntry : MealEntry -> Encode.Value
encoderMealEntry obj = Encode.object [ ("id", encoderUUID obj.id), ("recipeId", encoderUUID obj.recipeId), ("numberOfServings", Encode.float obj.numberOfServings) ]