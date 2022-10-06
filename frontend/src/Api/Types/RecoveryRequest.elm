module Api.Types.RecoveryRequest exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Api.Types.UUID exposing (..)

type alias RecoveryRequest = { userId: UUID }


decoderRecoveryRequest : Decode.Decoder RecoveryRequest
decoderRecoveryRequest = Decode.succeed RecoveryRequest |> required "userId" decoderUUID


encoderRecoveryRequest : RecoveryRequest -> Encode.Value
encoderRecoveryRequest obj = Encode.object [ ("userId", encoderUUID obj.userId) ]