module Api.Types.LoginContent exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Api.Types.UUID exposing (..)

type alias LoginContent = { userId: UUID, sessionId: UUID, nickname: String }


decoderLoginContent : Decode.Decoder LoginContent
decoderLoginContent = Decode.succeed LoginContent |> required "userId" decoderUUID |> required "sessionId" decoderUUID |> required "nickname" Decode.string


encoderLoginContent : LoginContent -> Encode.Value
encoderLoginContent obj = Encode.object [ ("userId", encoderUUID obj.userId), ("sessionId", encoderUUID obj.sessionId), ("nickname", Encode.string obj.nickname) ]