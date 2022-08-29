module Api.Types.Stats exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.Meal exposing (..)
import Api.Types.NutrientInformation exposing (..)

type alias Stats = { meals: (List Meal), nutrients: (List NutrientInformation) }


decoderStats : Decode.Decoder Stats
decoderStats = Decode.succeed Stats |> required "meals" (Decode.list (Decode.lazy (\_ -> decoderMeal))) |> required "nutrients" (Decode.list (Decode.lazy (\_ -> decoderNutrientInformation)))


encoderStats : Stats -> Encode.Value
encoderStats obj = Encode.object [ ("meals", Encode.list encoderMeal obj.meals), ("nutrients", Encode.list encoderNutrientInformation obj.nutrients) ]