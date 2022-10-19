module Api.Types.ReferenceValue exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias ReferenceValue = { nutrientCode: Int, referenceAmount: Float }


decoderReferenceValue : Decode.Decoder ReferenceValue
decoderReferenceValue = Decode.succeed ReferenceValue |> required "nutrientCode" Decode.int |> required "referenceAmount" Decode.float


encoderReferenceValue : ReferenceValue -> Encode.Value
encoderReferenceValue obj = Encode.object [ ("nutrientCode", Encode.int obj.nutrientCode), ("referenceAmount", Encode.float obj.referenceAmount) ]