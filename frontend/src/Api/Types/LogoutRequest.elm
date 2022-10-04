module Api.Types.LogoutRequest exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.Mode exposing (..)

type alias LogoutRequest = { mode: Mode }


decoderLogoutRequest : Decode.Decoder LogoutRequest
decoderLogoutRequest = Decode.succeed LogoutRequest |> required "mode" (Decode.lazy (\_ -> decoderMode))


encoderLogoutRequest : LogoutRequest -> Encode.Value
encoderLogoutRequest obj = Encode.object [ ("mode", encoderMode obj.mode) ]