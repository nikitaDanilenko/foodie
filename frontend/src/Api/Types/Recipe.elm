module Api.Types.Recipe exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Api.Types.Ingredient exposing (..)
import Api.Types.UUID exposing (..)

type alias Recipe = { id: UUID, name: String, description: (Maybe String), ingredients: (List Ingredient) }


decoderRecipe : Decode.Decoder Recipe
decoderRecipe = Decode.succeed Recipe |> required "id" decoderUUID |> required "name" Decode.string |> optional "description" (Decode.maybe Decode.string) Nothing |> required "ingredients" (Decode.list (Decode.lazy (\_ -> decoderIngredient)))


encoderRecipe : Recipe -> Encode.Value
encoderRecipe obj = Encode.object [ ("id", encoderUUID obj.id), ("name", Encode.string obj.name), ("description", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.description)), ("ingredients", Encode.list encoderIngredient obj.ingredients) ]