module Api.Types.MealEntryCreation exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Api.Types.UUID exposing (..)

type alias MealEntryCreation = { mealId: UUID, recipeId: UUID, factor: Float }


decoderMealEntryCreation : Decode.Decoder MealEntryCreation
decoderMealEntryCreation = Decode.succeed MealEntryCreation |> required "mealId" decoderUUID |> required "recipeId" decoderUUID |> required "factor" Decode.float


encoderMealEntryCreation : MealEntryCreation -> Encode.Value
encoderMealEntryCreation obj = Encode.object [ ("mealId", encoderUUID obj.mealId), ("recipeId", encoderUUID obj.recipeId), ("factor", Encode.float obj.factor) ]