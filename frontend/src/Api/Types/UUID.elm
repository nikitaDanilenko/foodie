module Api.Types.UUID exposing (..)

import Json.Decode as Decode

import Json.Encode as Encode

type alias UUID = UUID


decoderUUID : Decode.Decoder UUID
decoderUUID = Decode.string


encoderUUID : UUID -> Encode.Value
encoderUUID = Encode.string