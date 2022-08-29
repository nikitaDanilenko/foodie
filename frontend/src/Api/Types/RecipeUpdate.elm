module Api.Types.RecipeUpdate exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode

import Api.Types.UUID exposing (..)

type alias RecipeUpdate = { id: UUID, name: String, description: (Maybe String) }


decoderRecipeUpdate : Decode.Decoder RecipeUpdate
decoderRecipeUpdate = Decode.succeed RecipeUpdate |> required "id" decoderUUID |> required "name" Decode.string |> optional "description" (Decode.maybe Decode.string) Nothing


encoderRecipeUpdate : RecipeUpdate -> Encode.Value
encoderRecipeUpdate obj = Encode.object [ ("id", encoderUUID obj.id), ("name", Encode.string obj.name), ("description", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.description)) ]