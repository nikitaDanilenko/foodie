module Api.Types.Nutrient exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Api.Types.NutrientUnit exposing (..)

type alias Nutrient = { id: Int, code: Int, symbol: String, unit: NutrientUnit, name: String, nameFrench: String, tagName: (Maybe String), decimals: Int }


decoderNutrient : Decode.Decoder Nutrient
decoderNutrient = Decode.succeed Nutrient |> required "id" Decode.int |> required "code" Decode.int |> required "symbol" Decode.string |> required "unit" decoderNutrientUnit |> required "name" Decode.string |> required "nameFrench" Decode.string |> optional "tagName" (Decode.maybe Decode.string) Nothing |> required "decimals" Decode.int


encoderNutrient : Nutrient -> Encode.Value
encoderNutrient obj = Encode.object [ ("id", Encode.int obj.id), ("code", Encode.int obj.code), ("symbol", Encode.string obj.symbol), ("unit", encoderNutrientUnit obj.unit), ("name", Encode.string obj.name), ("nameFrench", Encode.string obj.nameFrench), ("tagName", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.tagName)), ("decimals", Encode.int obj.decimals) ]