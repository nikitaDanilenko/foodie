module Api.Types.Time exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias Time = { hour: Int, minute: Int }


decoderTime : Decode.Decoder Time
decoderTime = Decode.succeed Time |> required "hour" Decode.int |> required "minute" Decode.int


encoderTime : Time -> Encode.Value
encoderTime obj = Encode.object [ ("hour", Encode.int obj.hour), ("minute", Encode.int obj.minute) ]