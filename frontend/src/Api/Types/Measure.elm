module Api.Types.Measure exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias Measure = { id: Int, name: String }


decoderMeasure : Decode.Decoder Measure
decoderMeasure = Decode.succeed Measure |> required "id" Decode.int |> required "name" Decode.string


encoderMeasure : Measure -> Encode.Value
encoderMeasure obj = Encode.object [ ("id", Encode.int obj.id), ("name", Encode.string obj.name) ]