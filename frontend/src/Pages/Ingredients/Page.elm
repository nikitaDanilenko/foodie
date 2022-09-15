module Pages.Ingredients.Page exposing (..)

import Api.Auxiliary exposing (FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.Food exposing (Food)
import Api.Types.Ingredient exposing (Ingredient)
import Api.Types.Measure exposing (Measure)
import Api.Types.Recipe exposing (Recipe)
import Configuration exposing (Configuration)
import Dict exposing (Dict)
import Either exposing (Either(..))
import Http exposing (Error)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.Ingredients.IngredientCreationClientInput exposing (IngredientCreationClientInput)
import Pages.Ingredients.IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.Ingredients.RecipeInfo exposing (RecipeInfo)
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Util.Editing exposing (Editing)
import Util.LensUtil as LensUtil


type alias Model =
    { flagsWithJWT : FlagsWithJWT
    , recipeId : RecipeId
    , recipeInfo : Maybe RecipeInfo
    , ingredients : IngredientOrUpdateMap
    , foods : FoodMap
    , measures : MeasureMap
    , foodsSearchString : String
    , foodsToAdd : AddFoodsMap
    }


type alias IngredientOrUpdate =
    Either Ingredient (Editing Ingredient IngredientUpdateClientInput)


type alias FoodMap =
    Dict FoodId Food


type alias MeasureMap =
    Dict MeasureId Measure


type alias AddFoodsMap =
    Dict FoodId IngredientCreationClientInput


type alias IngredientOrUpdateMap =
    Dict IngredientId IngredientOrUpdate


lenses :
    { jwt : Lens Model JWT
    , foods : Lens Model FoodMap
    , measures : Lens Model MeasureMap
    , ingredients : Lens Model IngredientOrUpdateMap
    , foodsToAdd : Lens Model AddFoodsMap
    , foodsSearchString : Lens Model String
    , recipeInfo : Lens Model (Maybe RecipeInfo)
    }
lenses =
    { jwt = LensUtil.jwtSubLens
    , foods = Lens .foods (\b a -> { a | foods = b })
    , measures = Lens .measures (\b a -> { a | measures = b })
    , ingredients = Lens .ingredients (\b a -> { a | ingredients = b })
    , foodsToAdd = Lens .foodsToAdd (\b a -> { a | foodsToAdd = b })
    , foodsSearchString = Lens .foodsSearchString (\b a -> { a | foodsSearchString = b })
    , recipeInfo = Lens .recipeInfo (\b a -> { a | recipeInfo = b })
    }


type Msg
    = UpdateIngredient IngredientUpdateClientInput
    | SaveIngredientEdit IngredientId
    | GotSaveIngredientResponse (Result Error Ingredient)
    | EnterEditIngredient IngredientId
    | ExitEditIngredientAt IngredientId
    | DeleteIngredient IngredientId
    | GotDeleteIngredientResponse IngredientId (Result Error ())
    | GotFetchIngredientsResponse (Result Error (List Ingredient))
    | GotFetchFoodsResponse (Result Error (List Food))
    | GotFetchMeasuresResponse (Result Error (List Measure))
    | GotFetchRecipeResponse (Result Error Recipe)
    | SelectFood Food
    | DeselectFood FoodId
    | AddFood FoodId
    | GotAddFoodResponse (Result Error Ingredient)
    | UpdateAddFood IngredientCreationClientInput
    | UpdateJWT JWT
    | UpdateFoods String
    | UpdateMeasures String
    | SetFoodsSearchString String


type alias Flags =
    { configuration : Configuration
    , jwt : Maybe JWT
    , recipeId : RecipeId
    }


ingredientNameOrEmpty : FoodMap -> FoodId -> String
ingredientNameOrEmpty fm fi =
    Dict.get fi fm |> Maybe.Extra.unwrap "" .name
