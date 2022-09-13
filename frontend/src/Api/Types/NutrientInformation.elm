module Api.Types.NutrientInformation exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.Amounts exposing (..)
import Api.Types.NutrientUnit exposing (..)

type alias NutrientInformation = { nutrientCode: Int, name: String, symbol: String, unit: NutrientUnit, amounts: Amounts }


decoderNutrientInformation : Decode.Decoder NutrientInformation
decoderNutrientInformation = Decode.succeed NutrientInformation |> required "nutrientCode" Decode.int |> required "name" Decode.string |> required "symbol" Decode.string |> required "unit" decoderNutrientUnit |> required "amounts" (Decode.lazy (\_ -> decoderAmounts))


encoderNutrientInformation : NutrientInformation -> Encode.Value
encoderNutrientInformation obj = Encode.object [ ("nutrientCode", Encode.int obj.nutrientCode), ("name", Encode.string obj.name), ("symbol", Encode.string obj.symbol), ("unit", encoderNutrientUnit obj.unit), ("amounts", encoderAmounts obj.amounts) ]