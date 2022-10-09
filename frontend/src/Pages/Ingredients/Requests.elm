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
import Pages.Util.Links as Links
import Util.HttpUtil as HttpUtil


fetchIngredients : FlagsWithJWT -> RecipeId -> Cmd Page.Msg
fetchIngredients flags recipeId =
    fetchList
        { addressSuffix = [ "recipe", recipeId, "ingredient", "all" ]
        , decoder = decoderIngredient
        , gotMsg = Page.GotFetchIngredientsResponse
        }
        flags


fetchRecipe : FlagsWithJWT -> RecipeId -> Cmd Page.Msg
fetchRecipe flags recipeId =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Links.backendPage flags.configuration [ "recipe", recipeId ] []
        , expect = HttpUtil.expectJson Page.GotFetchRecipeResponse decoderRecipe
        }


fetchFoods : FlagsWithJWT -> Cmd Page.Msg
fetchFoods =
    fetchList
        { addressSuffix = [ "recipe", "foods" ]
        , decoder = decoderFood
        , gotMsg = Page.GotFetchFoodsResponse
        }


fetchMeasures : FlagsWithJWT -> Cmd Page.Msg
fetchMeasures =
    fetchList
        { addressSuffix = [ "recipe", "measures" ]
        , decoder = decoderMeasure
        , gotMsg = Page.GotFetchMeasuresResponse
        }


fetchList :
    { addressSuffix : List String
    , decoder : Decode.Decoder a
    , gotMsg : Result Error (List a) -> Page.Msg
    }
    -> FlagsWithJWT
    -> Cmd Page.Msg
fetchList ps flags =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Links.backendPage flags.configuration ps.addressSuffix []
        , expect = HttpUtil.expectJson ps.gotMsg (Decode.list ps.decoder)
        }


addFood : { configuration : Configuration, jwt : JWT, ingredientCreation : IngredientCreation } -> Cmd Page.Msg
addFood ps =
    HttpUtil.patchJsonWithJWT ps.jwt
        { url = Links.backendPage ps.configuration [ "recipe", "ingredient", "create" ] []
        , body = encoderIngredientCreation ps.ingredientCreation
        , expect = HttpUtil.expectJson Page.GotAddFoodResponse decoderIngredient
        }


saveIngredient : FlagsWithJWT -> IngredientUpdate -> Cmd Page.Msg
saveIngredient flags ingredientUpdate =
    HttpUtil.patchJsonWithJWT
        flags.jwt
        { url = Links.backendPage flags.configuration [ "recipe", "ingredient", "update" ] []
        , body = encoderIngredientUpdate ingredientUpdate
        , expect = HttpUtil.expectJson Page.GotSaveIngredientResponse decoderIngredient
        }


deleteIngredient : FlagsWithJWT -> IngredientId -> Cmd Page.Msg
deleteIngredient fs ingredientId =
    HttpUtil.deleteWithJWT fs.jwt
        { url = Links.backendPage fs.configuration [ "recipe", "ingredient", "delete", ingredientId ] []
        , expect = HttpUtil.expectWhatever (Page.GotDeleteIngredientResponse ingredientId)
        }
