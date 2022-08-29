module Api.Types.IngredientUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.AmountUnit exposing (..)
import Api.Types.UUID exposing (..)

type alias IngredientUpdate = { ingredientId: UUID, amountUnit: AmountUnit }


decoderIngredientUpdate : Decode.Decoder IngredientUpdate
decoderIngredientUpdate = Decode.succeed IngredientUpdate |> required "ingredientId" decoderUUID |> required "amountUnit" (Decode.lazy (\_ -> decoderAmountUnit))


encoderIngredientUpdate : IngredientUpdate -> Encode.Value
encoderIngredientUpdate obj = Encode.object [ ("ingredientId", encoderUUID obj.ingredientId), ("amountUnit", encoderAmountUnit obj.amountUnit) ]