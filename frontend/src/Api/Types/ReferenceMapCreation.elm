module Api.Types.ReferenceMapCreation exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias ReferenceMapCreation = { name: String }


decoderReferenceMapCreation : Decode.Decoder ReferenceMapCreation
decoderReferenceMapCreation = Decode.succeed ReferenceMapCreation |> required "name" Decode.string


encoderReferenceMapCreation : ReferenceMapCreation -> Encode.Value
encoderReferenceMapCreation obj = Encode.object [ ("name", Encode.string obj.name) ]