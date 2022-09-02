module Api.Types.Food exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.Measure exposing (..)

type alias Food = { id: Int, name: String, measures: (List Measure) }


decoderFood : Decode.Decoder Food
decoderFood = Decode.succeed Food |> required "id" Decode.int |> required "name" Decode.string |> required "measures" (Decode.list (Decode.lazy (\_ -> decoderMeasure)))


encoderFood : Food -> Encode.Value
encoderFood obj = Encode.object [ ("id", Encode.int obj.id), ("name", Encode.string obj.name), ("measures", Encode.list encoderMeasure obj.measures) ]