module Api.Types.ReferenceNutrientCreation exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias ReferenceNutrientCreation = { nutrientCode: Int, amount: Float }


decoderReferenceNutrientCreation : Decode.Decoder ReferenceNutrientCreation
decoderReferenceNutrientCreation = Decode.succeed ReferenceNutrientCreation |> required "nutrientCode" Decode.int |> required "amount" Decode.float


encoderReferenceNutrientCreation : ReferenceNutrientCreation -> Encode.Value
encoderReferenceNutrientCreation obj = Encode.object [ ("nutrientCode", Encode.int obj.nutrientCode), ("amount", Encode.float obj.amount) ]