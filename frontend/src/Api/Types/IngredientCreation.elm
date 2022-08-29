module Api.Types.IngredientCreation exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.AmountUnit exposing (..)
import Api.Types.UUID exposing (..)

type alias IngredientCreation = { recipeId: UUID, foodId: Int, amountUnit: AmountUnit }


decoderIngredientCreation : Decode.Decoder IngredientCreation
decoderIngredientCreation = Decode.succeed IngredientCreation |> required "recipeId" decoderUUID |> required "foodId" Decode.int |> required "amountUnit" (Decode.lazy (\_ -> decoderAmountUnit))


encoderIngredientCreation : IngredientCreation -> Encode.Value
encoderIngredientCreation obj = Encode.object [ ("recipeId", encoderUUID obj.recipeId), ("foodId", Encode.int obj.foodId), ("amountUnit", encoderAmountUnit obj.amountUnit) ]