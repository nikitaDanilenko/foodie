module Api.Types.ReferenceMapUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Api.Types.UUID exposing (..)

type alias ReferenceMapUpdate = { id: UUID, name: String }


decoderReferenceMapUpdate : Decode.Decoder ReferenceMapUpdate
decoderReferenceMapUpdate = Decode.succeed ReferenceMapUpdate |> required "id" decoderUUID |> required "name" Decode.string


encoderReferenceMapUpdate : ReferenceMapUpdate -> Encode.Value
encoderReferenceMapUpdate obj = Encode.object [ ("id", encoderUUID obj.id), ("name", Encode.string obj.name) ]