module Api.Types.UserUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias UserUpdate = { displayName: (Maybe String) }


decoderUserUpdate : Decode.Decoder UserUpdate
decoderUserUpdate = Decode.succeed UserUpdate |> optional "displayName" (Decode.maybe Decode.string) Nothing


encoderUserUpdate : UserUpdate -> Encode.Value
encoderUserUpdate obj = Encode.object [ ("displayName", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.displayName)) ]