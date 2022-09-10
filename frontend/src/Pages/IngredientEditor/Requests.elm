module Pages.IngredientEditor.Requests exposing
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
import Pages.IngredientEditor.Page as Page
import Url.Builder
import Util.HttpUtil as HttpUtil


fetchIngredients : Page.FlagsWithJWT -> Cmd Page.Msg
fetchIngredients flags =
    fetchList
        { addressSuffix = Url.Builder.relative [ "recipe", flags.recipeId, "ingredients" ] []
        , decoder = decoderIngredient
        , gotMsg = Page.GotFetchIngredientsResponse
        }
        flags


fetchRecipe : Page.FlagsWithJWT -> Cmd Page.Msg
fetchRecipe flags =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "recipe", flags.recipeId ] []
        , expect = HttpUtil.expectJson Page.GotFetchRecipeResponse decoderRecipe
        }


fetchFoods : Page.FlagsWithJWT -> Cmd Page.Msg
fetchFoods =
    fetchList
        { addressSuffix = Url.Builder.relative [ "recipe", "foods" ] []
        , decoder = decoderFood
        , gotMsg = Page.GotFetchFoodsResponse
        }


fetchMeasures : Page.FlagsWithJWT -> Cmd Page.Msg
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
    -> Page.FlagsWithJWT
    -> Cmd Page.Msg
fetchList ps flags =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, ps.addressSuffix ] []
        , expect = HttpUtil.expectJson ps.gotMsg (Decode.list ps.decoder)
        }


addFood : { configuration : Configuration, jwt : JWT, ingredientCreation : IngredientCreation } -> Cmd Page.Msg
addFood ps =
    HttpUtil.patchJsonWithJWT ps.jwt
        { url = Url.Builder.relative [ ps.configuration.backendURL, "recipe", "add-ingredient" ] []
        , body = encoderIngredientCreation ps.ingredientCreation
        , expect = HttpUtil.expectJson Page.GotAddFoodResponse decoderIngredient
        }


saveIngredient : Page.FlagsWithJWT -> IngredientUpdate -> Cmd Page.Msg
saveIngredient flags ingredientUpdate =
    HttpUtil.patchJsonWithJWT
        flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "recipe", "update-ingredient" ] []
        , body = encoderIngredientUpdate ingredientUpdate
        , expect = HttpUtil.expectJson Page.GotSaveIngredientResponse decoderIngredient
        }


deleteIngredient : Page.FlagsWithJWT -> IngredientId -> Cmd Page.Msg
deleteIngredient fs iid =
    HttpUtil.deleteWithJWT fs.jwt
        { url = Url.Builder.relative [ fs.configuration.backendURL, "recipe", "delete-ingredient", iid ] []
        , expect = HttpUtil.expectWhatever (Page.GotDeleteIngredientResponse iid)
        }
