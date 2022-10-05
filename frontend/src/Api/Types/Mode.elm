module Api.Types.Mode exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode


type Mode
    = All
    | This



-- todo: Consider a more automatic approach


decoderMode : Decode.Decoder Mode
decoderMode =
    Decode.string |> Decode.andThen decoderModeByString


decoderModeByString : String -> Decode.Decoder Mode
decoderModeByString string =
    case string of
        "All" ->
            Decode.succeed All

        "This" ->
            Decode.succeed This

        _ ->
            Decode.fail ("Unexpected type for Mode: " ++ string)


encoderMode : Mode -> Encode.Value
encoderMode =
    toString >> Encode.string


toString : Mode -> String
toString mode =
    case mode of
        All ->
            "All"

        This ->
            "This"
