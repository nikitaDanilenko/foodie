module Api.Types.AmountUnit exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias AmountUnit = { measureId: (Maybe Int), factor: Float }


decoderAmountUnit : Decode.Decoder AmountUnit
decoderAmountUnit = Decode.succeed AmountUnit |> optional "measureId" (Decode.maybe Decode.int) Nothing |> required "factor" Decode.float


encoderAmountUnit : AmountUnit -> Encode.Value
encoderAmountUnit obj = Encode.object [ ("measureId", Maybe.withDefault Encode.null (Maybe.map Encode.int obj.measureId)), ("factor", Encode.float obj.factor) ]