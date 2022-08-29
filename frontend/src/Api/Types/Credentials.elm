module Api.Types.Credentials exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias Credentials = { nickname: String, password: String }


decoderCredentials : Decode.Decoder Credentials
decoderCredentials = Decode.succeed Credentials |> required "nickname" Decode.string |> required "password" Decode.string


encoderCredentials : Credentials -> Encode.Value
encoderCredentials obj = Encode.object [ ("nickname", Encode.string obj.nickname), ("password", Encode.string obj.password) ]