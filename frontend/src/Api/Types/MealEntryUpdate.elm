module Api.Types.MealEntryUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Api.Types.UUID exposing (..)

type alias MealEntryUpdate = { mealEntryId: UUID, recipeId: UUID, numberOfServings: Float }


decoderMealEntryUpdate : Decode.Decoder MealEntryUpdate
decoderMealEntryUpdate = Decode.succeed MealEntryUpdate |> required "mealEntryId" decoderUUID |> required "recipeId" decoderUUID |> required "numberOfServings" Decode.float


encoderMealEntryUpdate : MealEntryUpdate -> Encode.Value
encoderMealEntryUpdate obj = Encode.object [ ("mealEntryId", encoderUUID obj.mealEntryId), ("recipeId", encoderUUID obj.recipeId), ("numberOfServings", Encode.float obj.numberOfServings) ]