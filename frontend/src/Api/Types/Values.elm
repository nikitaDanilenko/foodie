module Api.Types.Values exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias Values = { total: Float, dailyAverage: Float }


decoderValues : Decode.Decoder Values
decoderValues = Decode.succeed Values |> required "total" Decode.float |> required "dailyAverage" Decode.float


encoderValues : Values -> Encode.Value
encoderValues obj = Encode.object [ ("total", Encode.float obj.total), ("dailyAverage", Encode.float obj.dailyAverage) ]