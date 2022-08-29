module Api.Types.SimpleDate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.Date exposing (..)
import Api.Types.Time exposing (..)

type alias SimpleDate = { date: Date, time: (Maybe Time) }


decoderSimpleDate : Decode.Decoder SimpleDate
decoderSimpleDate = Decode.succeed SimpleDate |> required "date" (Decode.lazy (\_ -> decoderDate)) |> optional "time" (Decode.maybe (Decode.lazy (\_ -> decoderTime))) Nothing


encoderSimpleDate : SimpleDate -> Encode.Value
encoderSimpleDate obj = Encode.object [ ("date", encoderDate obj.date), ("time", Maybe.withDefault Encode.null (Maybe.map encoderTime obj.time)) ]