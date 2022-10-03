module Api.Types.User exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Api.Types.UUID exposing (..)

type alias User = { id: UUID, nickname: String, displayName: (Maybe String), email: String }


decoderUser : Decode.Decoder User
decoderUser = Decode.succeed User |> required "id" decoderUUID |> required "nickname" Decode.string |> optional "displayName" (Decode.maybe Decode.string) Nothing |> required "email" Decode.string


encoderUser : User -> Encode.Value
encoderUser obj = Encode.object [ ("id", encoderUUID obj.id), ("nickname", Encode.string obj.nickname), ("displayName", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.displayName)), ("email", Encode.string obj.email) ]