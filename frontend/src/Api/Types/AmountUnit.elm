module Api.Types.AmountUnit exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias AmountUnit = { measureId: Int, factor: Float }


decoderAmountUnit : Decode.Decoder AmountUnit
decoderAmountUnit = Decode.succeed AmountUnit |> required "measureId" Decode.int |> required "factor" Decode.float


encoderAmountUnit : AmountUnit -> Encode.Value
encoderAmountUnit obj = Encode.object [ ("measureId", Encode.int obj.measureId), ("factor", Encode.float obj.factor) ]