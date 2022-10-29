module Pages.Ingredients.Page exposing (..)

import Api.Auxiliary exposing (ComplexFoodId, ComplexIngredientId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexIngredient exposing (ComplexIngredient)
import Api.Types.Food exposing (Food)
import Api.Types.Ingredient exposing (Ingredient)
import Api.Types.Measure exposing (Measure)
import Api.Types.Recipe exposing (Recipe)
import Dict exposing (Dict)
import Monocle.Lens exposing (Lens)
import Pages.Ingredients.ComplexIngredientClientInput exposing (ComplexIngredientClientInput)
import Pages.Ingredients.FoodGroup as FoodGroup exposing (FoodGroup)
import Pages.Ingredients.IngredientCreationClientInput exposing (IngredientCreationClientInput)
import Pages.Ingredients.IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.Ingredients.Pagination exposing (Pagination)
import Pages.Ingredients.RecipeInfo exposing (RecipeInfo)
import Pages.Ingredients.Status exposing (Status)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , recipeId : RecipeId
    , recipeInfo : Maybe RecipeInfo
    , allRecipes : RecipeMap
    , ingredientsGroup : FoodGroup IngredientId Ingredient IngredientUpdateClientInput FoodId Food IngredientCreationClientInput
    , complexIngredientsGroup : FoodGroup ComplexIngredientId ComplexIngredient ComplexIngredientClientInput ComplexFoodId ComplexFood ComplexIngredientClientInput
    , measures : MeasureMap
    , initialization : Initialization Status
    , foodsMode : FoodsMode
    }


type alias PlainIngredientOrUpdate =
    FoodGroup.IngredientOrUpdate Ingredient IngredientUpdateClientInput


type alias ComplexIngredientOrUpdate =
    FoodGroup.IngredientOrUpdate ComplexIngredient ComplexIngredientClientInput


type alias FoodMap =
    Dict FoodId Food


type alias ComplexFoodMap =
    Dict ComplexFoodId ComplexFood


type alias RecipeMap =
    Dict RecipeId Recipe


type alias MeasureMap =
    Dict MeasureId Measure


type alias AddFoodsMap =
    Dict FoodId IngredientCreationClientInput


type alias AddComplexFoodsMap =
    Dict ComplexFoodId ComplexIngredientClientInput


type alias PlainIngredientOrUpdateMap =
    Dict IngredientId PlainIngredientOrUpdate


type alias ComplexIngredientOrUpdateMap =
    Dict ComplexIngredientId ComplexIngredientOrUpdate


type FoodsMode
    = Plain
    | Complex


lenses :
    { measures : Lens Model MeasureMap
    , ingredientsGroup : Lens Model (FoodGroup IngredientId Ingredient IngredientUpdateClientInput FoodId Food IngredientCreationClientInput)
    , complexIngredientsGroup : Lens Model (FoodGroup ComplexIngredientId ComplexIngredient ComplexIngredientClientInput ComplexFoodId ComplexFood ComplexIngredientClientInput)
    , recipeInfo : Lens Model (Maybe RecipeInfo)
    , allRecipes : Lens Model RecipeMap
    , initialization : Lens Model (Initialization Status)
    , foodsMode : Lens Model FoodsMode
    }
lenses =
    { measures = Lens .measures (\b a -> { a | measures = b })
    , ingredientsGroup = Lens .ingredientsGroup (\b a -> { a | ingredientsGroup = b })
    , complexIngredientsGroup = Lens .complexIngredientsGroup (\b a -> { a | complexIngredientsGroup = b })
    , recipeInfo = Lens .recipeInfo (\b a -> { a | recipeInfo = b })
    , allRecipes = Lens .allRecipes (\b a -> { a | allRecipes = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , foodsMode = Lens .foodsMode (\b a -> { a | foodsMode = b })
    }


type Msg
    = UpdateIngredient IngredientUpdateClientInput
    | UpdateComplexIngredient ComplexIngredientClientInput
    | SaveIngredientEdit IngredientUpdateClientInput
    | SaveComplexIngredientEdit ComplexIngredientClientInput
    | GotSaveIngredientResponse (Result Error Ingredient)
    | GotSaveComplexIngredientResponse (Result Error ComplexIngredient)
    | EnterEditIngredient IngredientId
    | EnterEditComplexIngredient ComplexIngredientId
    | ExitEditIngredientAt IngredientId
    | ExitEditComplexIngredientAt ComplexIngredientId
    | DeleteIngredient IngredientId
    | DeleteComplexIngredient ComplexIngredientId
    | GotDeleteIngredientResponse IngredientId (Result Error ())
    | GotDeleteComplexIngredientResponse ComplexIngredientId (Result Error ())
    | GotFetchIngredientsResponse (Result Error (List Ingredient))
    | GotFetchComplexIngredientsResponse (Result Error (List ComplexIngredient))
    | GotFetchFoodsResponse (Result Error (List Food))
    | GotFetchComplexFoodsResponse (Result Error (List ComplexFood))
    | GotFetchMeasuresResponse (Result Error (List Measure))
    | GotFetchRecipeResponse (Result Error Recipe)
    | GotFetchRecipesResponse (Result Error (List Recipe))
    | SelectFood Food
    | SelectComplexFood ComplexFood
    | DeselectFood FoodId
    | DeselectComplexFood ComplexFoodId
    | AddFood FoodId
    | AddComplexFood ComplexFoodId
    | GotAddFoodResponse (Result Error Ingredient)
    | GotAddComplexFoodResponse (Result Error ComplexIngredient)
    | UpdateAddFood IngredientCreationClientInput
    | UpdateAddComplexFood ComplexIngredientClientInput
    | UpdateFoods String
    | UpdateMeasures String
    | SetFoodsSearchString String
    | SetComplexFoodsSearchString String
    | SetIngredientsPagination Pagination
    | SetComplexIngredientsPagination Pagination
    | ChangeFoodsMode FoodsMode


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , recipeId : RecipeId
    }
