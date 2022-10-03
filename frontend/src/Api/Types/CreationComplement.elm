module Api.Types.CreationComplement exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias CreationComplement = { displayName: (Maybe String), password: String }


decoderCreationComplement : Decode.Decoder CreationComplement
decoderCreationComplement = Decode.succeed CreationComplement |> optional "displayName" (Decode.maybe Decode.string) Nothing |> required "password" Decode.string


encoderCreationComplement : CreationComplement -> Encode.Value
encoderCreationComplement obj = Encode.object [ ("displayName", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.displayName)), ("password", Encode.string obj.password) ]