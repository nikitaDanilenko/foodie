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


type alias MealId =
    UUID


type alias MealEntryId =
    UUID


type alias NutrientCode =
    Int


type alias UserId =
    UUID


type alias JWT =
    String


type alias ReferenceMapId =
    UUID


type alias ComplexFoodId =
    RecipeId


type alias ComplexIngredientId =
    RecipeId
