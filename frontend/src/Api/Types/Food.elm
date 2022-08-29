module Api.Types.Food exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias Food = { id: Int, name: String }


decoderFood : Decode.Decoder Food
decoderFood = Decode.succeed Food |> required "id" Decode.int |> required "name" Decode.string


encoderFood : Food -> Encode.Value
encoderFood obj = Encode.object [ ("id", Encode.int obj.id), ("name", Encode.string obj.name) ]