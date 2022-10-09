module Pages.Ingredients.Requests exposing
    ( addFood
    , deleteIngredient
    , fetchFoods
    , fetchIngredients
    , fetchMeasures
    , fetchRecipe
    , saveIngredient
    )

import Addresses.Backend
import Api.Auxiliary exposing (FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.Food exposing (Food, decoderFood)
import Api.Types.Ingredient exposing (Ingredient, decoderIngredient)
import Api.Types.IngredientCreation exposing (IngredientCreation, encoderIngredientCreation)
import Api.Types.IngredientUpdate exposing (IngredientUpdate, encoderIngredientUpdate)
import Api.Types.Measure exposing (Measure, decoderMeasure)
import Api.Types.Recipe exposing (Recipe, decoderRecipe)
import Configuration exposing (Configuration)
import Http exposing (Error)
import Json.Decode as Decode
import Pages.Ingredients.Page as Page
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Util.HttpUtil as HttpUtil


fetchIngredients : FlagsWithJWT -> RecipeId -> Cmd Page.Msg
fetchIngredients flags recipeId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.ingredients.allOf recipeId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchIngredientsResponse (Decode.list decoderIngredient)
        }


fetchRecipe : FlagsWithJWT -> RecipeId -> Cmd Page.Msg
fetchRecipe flags recipeId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.single recipeId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchRecipeResponse decoderRecipe
        }


fetchFoods : FlagsWithJWT -> Cmd Page.Msg
fetchFoods flags =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.recipes.foods
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchFoodsResponse (Decode.list decoderFood)
        }


fetchMeasures : FlagsWithJWT -> Cmd Page.Msg
fetchMeasures flags =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.recipes.measures
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchMeasuresResponse (Decode.list decoderMeasure)
        }


addFood :
    { configuration : Configuration
    , jwt : JWT
    , ingredientCreation : IngredientCreation
    }
    -> Cmd Page.Msg
addFood ps =
    HttpUtil.runPatternWithJwt
        { configuration = ps.configuration
        , jwt = ps.jwt
        }
        Addresses.Backend.recipes.ingredients.create
        { body = encoderIngredientCreation ps.ingredientCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotAddFoodResponse decoderIngredient
        }


saveIngredient : FlagsWithJWT -> IngredientUpdate -> Cmd Page.Msg
saveIngredient flags ingredientUpdate =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.recipes.ingredients.update
        { body = encoderIngredientUpdate ingredientUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotSaveIngredientResponse decoderIngredient
        }


deleteIngredient : FlagsWithJWT -> IngredientId -> Cmd Page.Msg
deleteIngredient flags ingredientId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.ingredients.delete ingredientId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (Page.GotDeleteIngredientResponse ingredientId)
        }
