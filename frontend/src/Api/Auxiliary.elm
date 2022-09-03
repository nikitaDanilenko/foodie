module Api.Auxiliary exposing (..)

import Api.Types.UUID exposing (UUID)


type alias RecipeId =
    UUID


type alias IngredientId =
    UUID


type alias MeasureId =
    Int


type alias FoodId =
    Int


type alias JWT =
    String
