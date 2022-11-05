module Api.Types.Amounts exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.Values exposing (..)

type alias Amounts = { values: (Maybe Values), numberOfIngredients: Int, numberOfDefinedValues: Int }


decoderAmounts : Decode.Decoder Amounts
decoderAmounts = Decode.succeed Amounts |> optional "values" (Decode.maybe (Decode.lazy (\_ -> decoderValues))) Nothing |> required "numberOfIngredients" Decode.int |> required "numberOfDefinedValues" Decode.int


encoderAmounts : Amounts -> Encode.Value
encoderAmounts obj = Encode.object [ ("values", Maybe.withDefault Encode.null (Maybe.map encoderValues obj.values)), ("numberOfIngredients", Encode.int obj.numberOfIngredients), ("numberOfDefinedValues", Encode.int obj.numberOfDefinedValues) ]