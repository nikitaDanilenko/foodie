module Api.Types.ReferenceNutrient exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias ReferenceNutrient = { nutrientCode: Int, amount: Float }


decoderReferenceNutrient : Decode.Decoder ReferenceNutrient
decoderReferenceNutrient = Decode.succeed ReferenceNutrient |> required "nutrientCode" Decode.int |> required "amount" Decode.float


encoderReferenceNutrient : ReferenceNutrient -> Encode.Value
encoderReferenceNutrient obj = Encode.object [ ("nutrientCode", Encode.int obj.nutrientCode), ("amount", Encode.float obj.amount) ]