module Pages.Ingredients.Page exposing (..)

import Api.Auxiliary exposing (ComplexFoodId, ComplexIngredientId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexIngredient exposing (ComplexIngredient)
import Api.Types.Food exposing (Food)
import Api.Types.Ingredient exposing (Ingredient)
import Api.Types.Measure exposing (Measure)
import Api.Types.Recipe exposing (Recipe)
import Dict exposing (Dict)
import Http exposing (Error)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.Ingredients.ComplexIngredientClientInput exposing (ComplexIngredientClientInput)
import Pages.Ingredients.FoodGroup as FoodGroup exposing (FoodGroup)
import Pages.Ingredients.IngredientCreationClientInput exposing (IngredientCreationClientInput)
import Pages.Ingredients.IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.Ingredients.Pagination exposing (Pagination)
import Pages.Ingredients.RecipeInfo exposing (RecipeInfo)
import Pages.Ingredients.Status exposing (Status)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , recipeId : RecipeId
    , recipeInfo : Maybe RecipeInfo
    , ingredientsGroup : FoodGroup IngredientId Ingredient IngredientUpdateClientInput FoodId Food IngredientCreationClientInput
    , complexIngredientsGroup : FoodGroup ComplexIngredientId ComplexIngredient ComplexIngredientClientInput ComplexFoodId ComplexFood ComplexIngredientClientInput
    , measures : MeasureMap
    , initialization : Initialization Status
    }


type alias PlainIngredientOrUpdate =
    FoodGroup.IngredientOrUpdate Ingredient IngredientUpdateClientInput


type alias FoodMap =
    Dict FoodId Food


type alias MeasureMap =
    Dict MeasureId Measure


type alias AddFoodsMap =
    Dict FoodId IngredientCreationClientInput


type alias PlainIngredientOrUpdateMap =
    Dict IngredientId PlainIngredientOrUpdate


lenses :
    { measures : Lens Model MeasureMap
    , ingredientsGroup : Lens Model (FoodGroup IngredientId Ingredient IngredientUpdateClientInput FoodId Food IngredientCreationClientInput)
    , complexIngredientsGroup : Lens Model (FoodGroup ComplexIngredientId ComplexIngredient ComplexIngredientClientInput ComplexFoodId ComplexFood ComplexIngredientClientInput)
    , recipeInfo : Lens Model (Maybe RecipeInfo)
    , initialization : Lens Model (Initialization Status)
    }
lenses =
    { measures = Lens .measures (\b a -> { a | measures = b })
    , ingredientsGroup = Lens .ingredientsGroup (\b a -> { a | ingredientsGroup = b })
    , complexIngredientsGroup = Lens .complexIngredientsGroup (\b a -> { a | complexIngredientsGroup = b })
    , recipeInfo = Lens .recipeInfo (\b a -> { a | recipeInfo = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    }


type Msg
    = UpdateIngredient IngredientUpdateClientInput
    | SaveIngredientEdit IngredientUpdateClientInput
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
    | UpdateFoods String
    | UpdateMeasures String
    | SetFoodsSearchString String
    | SetPagination Pagination


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , recipeId : RecipeId
    }


ingredientNameOrEmpty : FoodMap -> FoodId -> String
ingredientNameOrEmpty fm fi =
    Dict.get fi fm |> Maybe.Extra.unwrap "" .name
