module Pages.Ingredients.Requests exposing
    ( addFood
    , deleteIngredient
    , fetchFoods
    , fetchIngredients
    , fetchMeasures
    , fetchRecipe
    , saveIngredient
    )

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
import Url.Builder
import Util.HttpUtil as HttpUtil


fetchIngredients : FlagsWithJWT -> RecipeId -> Cmd Page.Msg
fetchIngredients flags recipeId =
    fetchList
        { addressSuffix = Url.Builder.relative [ "recipe", recipeId, "ingredient", "all" ] []
        , decoder = decoderIngredient
        , gotMsg = Page.GotFetchIngredientsResponse
        }
        flags


fetchRecipe : FlagsWithJWT -> RecipeId -> Cmd Page.Msg
fetchRecipe flags recipeId =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "recipe", recipeId ] []
        , expect = HttpUtil.expectJson Page.GotFetchRecipeResponse decoderRecipe
        }


fetchFoods : FlagsWithJWT -> Cmd Page.Msg
fetchFoods =
    fetchList
        { addressSuffix = Url.Builder.relative [ "recipe", "foods" ] []
        , decoder = decoderFood
        , gotMsg = Page.GotFetchFoodsResponse
        }


fetchMeasures : FlagsWithJWT -> Cmd Page.Msg
fetchMeasures =
    fetchList
        { addressSuffix = Url.Builder.relative [ "recipe", "measures" ] []
        , decoder = decoderMeasure
        , gotMsg = Page.GotFetchMeasuresResponse
        }


fetchList :
    { addressSuffix : String
    , decoder : Decode.Decoder a
    , gotMsg : Result Error (List a) -> Page.Msg
    }
    -> FlagsWithJWT
    -> Cmd Page.Msg
fetchList ps flags =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, ps.addressSuffix ] []
        , expect = HttpUtil.expectJson ps.gotMsg (Decode.list ps.decoder)
        }


addFood : { configuration : Configuration, jwt : JWT, ingredientCreation : IngredientCreation } -> Cmd Page.Msg
addFood ps =
    HttpUtil.patchJsonWithJWT ps.jwt
        { url = Url.Builder.relative [ ps.configuration.backendURL, "recipe", "ingredient", "create" ] []
        , body = encoderIngredientCreation ps.ingredientCreation
        , expect = HttpUtil.expectJson Page.GotAddFoodResponse decoderIngredient
        }


saveIngredient : FlagsWithJWT -> IngredientUpdate -> Cmd Page.Msg
saveIngredient flags ingredientUpdate =
    HttpUtil.patchJsonWithJWT
        flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "recipe", "ingredient", "update" ] []
        , body = encoderIngredientUpdate ingredientUpdate
        , expect = HttpUtil.expectJson Page.GotSaveIngredientResponse decoderIngredient
        }


deleteIngredient : FlagsWithJWT -> IngredientId -> Cmd Page.Msg
deleteIngredient fs iid =
    HttpUtil.deleteWithJWT fs.jwt
        { url = Url.Builder.relative [ fs.configuration.backendURL, "recipe", "ingredient", "delete", iid ] []
        , expect = HttpUtil.expectWhatever (Page.GotDeleteIngredientResponse iid)
        }
