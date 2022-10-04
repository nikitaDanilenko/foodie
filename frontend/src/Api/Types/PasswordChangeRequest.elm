module Api.Types.PasswordChangeRequest exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias PasswordChangeRequest = { password: String }


decoderPasswordChangeRequest : Decode.Decoder PasswordChangeRequest
decoderPasswordChangeRequest = Decode.succeed PasswordChangeRequest |> required "password" Decode.string


encoderPasswordChangeRequest : PasswordChangeRequest -> Encode.Value
encoderPasswordChangeRequest obj = Encode.object [ ("password", Encode.string obj.password) ]