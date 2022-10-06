module Api.Types.RecoveryRequest exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias RecoveryRequest = { identifier: String }


decoderRecoveryRequest : Decode.Decoder RecoveryRequest
decoderRecoveryRequest = Decode.succeed RecoveryRequest |> required "identifier" Decode.string


encoderRecoveryRequest : RecoveryRequest -> Encode.Value
encoderRecoveryRequest obj = Encode.object [ ("identifier", Encode.string obj.identifier) ]