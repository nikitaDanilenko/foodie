module Api.Types.Meal exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.SimpleDate exposing (..)
import Api.Types.MealEntry exposing (..)
import Api.Types.UUID exposing (..)

type alias Meal = { id: UUID, date: SimpleDate, name: (Maybe String), entries: (List MealEntry) }


decoderMeal : Decode.Decoder Meal
decoderMeal = Decode.succeed Meal |> required "id" decoderUUID |> required "date" (Decode.lazy (\_ -> decoderSimpleDate)) |> optional "name" (Decode.maybe Decode.string) Nothing |> required "entries" (Decode.list (Decode.lazy (\_ -> decoderMealEntry)))


encoderMeal : Meal -> Encode.Value
encoderMeal obj = Encode.object [ ("id", encoderUUID obj.id), ("date", encoderSimpleDate obj.date), ("name", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.name)), ("entries", Encode.list encoderMealEntry obj.entries) ]