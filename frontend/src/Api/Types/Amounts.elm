module Api.Types.Amounts exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias Amounts = { total: Float, dailyAverage: Float }


decoderAmounts : Decode.Decoder Amounts
decoderAmounts = Decode.succeed Amounts |> required "total" Decode.float |> required "dailyAverage" Decode.float


encoderAmounts : Amounts -> Encode.Value
encoderAmounts obj = Encode.object [ ("total", Encode.float obj.total), ("dailyAverage", Encode.float obj.dailyAverage) ]