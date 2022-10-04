module Api.Types.Mode exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type Mode = All | This


decoderMode : Decode.Decoder Mode
decoderMode = Decode.field "type" Decode.string |> Decode.andThen decoderModeTpe

decoderModeTpe : String -> Decode.Decoder Mode
decoderModeTpe tpe =
   case tpe of
      "All" -> Decode.succeed All
      "This" -> Decode.succeed This
      _ -> Decode.fail ("Unexpected type for Mode: " ++ tpe)


encoderMode : Mode -> Encode.Value
encoderMode tpe =
   case tpe of
      All -> Encode.object [ ("type", Encode.string "All") ]
      This -> Encode.object [ ("type", Encode.string "This") ]