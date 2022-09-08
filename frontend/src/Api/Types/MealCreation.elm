module Api.Types.MealCreation exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.SimpleDate exposing (..)

type alias MealCreation = { date: SimpleDate, name: (Maybe String), amount: Float }


decoderMealCreation : Decode.Decoder MealCreation
decoderMealCreation = Decode.succeed MealCreation |> required "date" (Decode.lazy (\_ -> decoderSimpleDate)) |> optional "name" (Decode.maybe Decode.string) Nothing |> required "amount" Decode.float


encoderMealCreation : MealCreation -> Encode.Value
encoderMealCreation obj = Encode.object [ ("date", encoderSimpleDate obj.date), ("name", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.name)), ("amount", Encode.float obj.amount) ]