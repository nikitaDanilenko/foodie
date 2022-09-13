module Api.Types.ReferenceNutrientUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias ReferenceNutrientUpdate = { nutrientCode: Int, amount: Float }


decoderReferenceNutrientUpdate : Decode.Decoder ReferenceNutrientUpdate
decoderReferenceNutrientUpdate = Decode.succeed ReferenceNutrientUpdate |> required "nutrientCode" Decode.int |> required "amount" Decode.float


encoderReferenceNutrientUpdate : ReferenceNutrientUpdate -> Encode.Value
encoderReferenceNutrientUpdate obj = Encode.object [ ("nutrientCode", Encode.int obj.nutrientCode), ("amount", Encode.float obj.amount) ]