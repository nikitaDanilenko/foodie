module Api.Auxiliary exposing (..)

import Api.Types.UUID exposing (UUID)


type alias RecipeId =
    UUID


type alias IngredientId =
    UUID

type alias JWT =
  String