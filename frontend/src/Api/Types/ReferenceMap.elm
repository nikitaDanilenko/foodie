module Api.Types.ReferenceMap exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Api.Types.UUID exposing (..)

type alias ReferenceMap = { id: UUID, name: String }


decoderReferenceMap : Decode.Decoder ReferenceMap
decoderReferenceMap = Decode.succeed ReferenceMap |> required "id" decoderUUID |> required "name" Decode.string


encoderReferenceMap : ReferenceMap -> Encode.Value
encoderReferenceMap obj = Encode.object [ ("id", encoderUUID obj.id), ("name", Encode.string obj.name) ]