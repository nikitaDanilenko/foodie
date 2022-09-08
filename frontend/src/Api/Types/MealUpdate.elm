module Api.Types.MealUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.SimpleDate exposing (..)
import Api.Types.UUID exposing (..)

type alias MealUpdate = { id: UUID, date: SimpleDate, name: (Maybe String) }


decoderMealUpdate : Decode.Decoder MealUpdate
decoderMealUpdate = Decode.succeed MealUpdate |> required "id" decoderUUID |> required "date" (Decode.lazy (\_ -> decoderSimpleDate)) |> optional "name" (Decode.maybe Decode.string) Nothing


encoderMealUpdate : MealUpdate -> Encode.Value
encoderMealUpdate obj = Encode.object [ ("id", encoderUUID obj.id), ("date", encoderSimpleDate obj.date), ("name", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.name)) ]