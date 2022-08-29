module Api.Types.Ingredient exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.AmountUnit exposing (..)
import Api.Types.UUID exposing (..)

type alias Ingredient = { id: UUID, foodId: Int, amountUnit: AmountUnit }


decoderIngredient : Decode.Decoder Ingredient
decoderIngredient = Decode.succeed Ingredient |> required "id" decoderUUID |> required "foodId" Decode.int |> required "amountUnit" (Decode.lazy (\_ -> decoderAmountUnit))


encoderIngredient : Ingredient -> Encode.Value
encoderIngredient obj = Encode.object [ ("id", encoderUUID obj.id), ("foodId", Encode.int obj.foodId), ("amountUnit", encoderAmountUnit obj.amountUnit) ]