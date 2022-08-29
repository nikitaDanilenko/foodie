module Api.Types.Date exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias Date = { year: Int, month: Int, day: Int }


decoderDate : Decode.Decoder Date
decoderDate = Decode.succeed Date |> required "year" Decode.int |> required "month" Decode.int |> required "day" Decode.int


encoderDate : Date -> Encode.Value
encoderDate obj = Encode.object [ ("year", Encode.int obj.year), ("month", Encode.int obj.month), ("day", Encode.int obj.day) ]