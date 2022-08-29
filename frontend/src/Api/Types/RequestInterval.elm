module Api.Types.RequestInterval exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.Date exposing (..)

type alias RequestInterval = { from: (Maybe Date), to: (Maybe Date) }


decoderRequestInterval : Decode.Decoder RequestInterval
decoderRequestInterval = Decode.succeed RequestInterval |> optional "from" (Decode.maybe (Decode.lazy (\_ -> decoderDate))) Nothing |> optional "to" (Decode.maybe (Decode.lazy (\_ -> decoderDate))) Nothing


encoderRequestInterval : RequestInterval -> Encode.Value
encoderRequestInterval obj = Encode.object [ ("from", Maybe.withDefault Encode.null (Maybe.map encoderDate obj.from)), ("to", Maybe.withDefault Encode.null (Maybe.map encoderDate obj.to)) ]