module Api.Types.RecipeCreation exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode


type alias RecipeCreation = { name: String, description: (Maybe String) }


decoderRecipeCreation : Decode.Decoder RecipeCreation
decoderRecipeCreation = Decode.succeed RecipeCreation |> required "name" Decode.string |> optional "description" (Decode.maybe Decode.string) Nothing


encoderRecipeCreation : RecipeCreation -> Encode.Value
encoderRecipeCreation obj = Encode.object [ ("name", Encode.string obj.name), ("description", Maybe.withDefault Encode.null (Maybe.map Encode.string obj.description)) ]