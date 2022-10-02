module Api.Types.UserIdentifier exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias UserIdentifier = { nickname: String, email: String }


decoderUserIdentifier : Decode.Decoder UserIdentifier
decoderUserIdentifier = Decode.succeed UserIdentifier |> required "nickname" Decode.string |> required "email" Decode.string


encoderUserIdentifier : UserIdentifier -> Encode.Value
encoderUserIdentifier obj = Encode.object [ ("nickname", Encode.string obj.nickname), ("email", Encode.string obj.email) ]