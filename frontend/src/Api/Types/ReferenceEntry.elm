module Api.Types.ReferenceEntry exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias ReferenceEntry = { nutrientCode: Int, amount: Float }


decoderReferenceEntry : Decode.Decoder ReferenceEntry
decoderReferenceEntry = Decode.succeed ReferenceEntry |> required "nutrientCode" Decode.int |> required "amount" Decode.float


encoderReferenceEntry : ReferenceEntry -> Encode.Value
encoderReferenceEntry obj = Encode.object [ ("nutrientCode", Encode.int obj.nutrientCode), ("amount", Encode.float obj.amount) ]