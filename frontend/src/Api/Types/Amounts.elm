module Api.Types.Amounts exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias Amounts = { total: Float, dailyAverage: Float, referenceDailyAverage: (Maybe Float) }


decoderAmounts : Decode.Decoder Amounts
decoderAmounts = Decode.succeed Amounts |> required "total" Decode.float |> required "dailyAverage" Decode.float |> optional "referenceDailyAverage" (Decode.maybe Decode.float) Nothing


encoderAmounts : Amounts -> Encode.Value
encoderAmounts obj = Encode.object [ ("total", Encode.float obj.total), ("dailyAverage", Encode.float obj.dailyAverage), ("referenceDailyAverage", Maybe.withDefault Encode.null (Maybe.map Encode.float obj.referenceDailyAverage)) ]