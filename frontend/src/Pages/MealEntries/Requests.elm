module Pages.MealEntries.Requests exposing
    ( AddMealEntryParams
    , addMealEntry
    , deleteMealEntry
    , fetchMeal
    , fetchMealEntries
    , fetchRecipes
    , saveMealEntry
    )

import Api.Auxiliary exposing (JWT, MealEntryId, MealId, RecipeId)
import Api.Types.Meal exposing (decoderMeal)
import Api.Types.MealEntry exposing (MealEntry, decoderMealEntry)
import Api.Types.MealEntryCreation exposing (MealEntryCreation, encoderMealEntryCreation)
import Api.Types.MealEntryUpdate exposing (MealEntryUpdate, encoderMealEntryUpdate)
import Api.Types.Recipe exposing (Recipe, decoderRecipe)
import Configuration exposing (Configuration)
import Json.Decode as Decode
import Pages.MealEntries.Page exposing (Msg(..), RecipeMap)
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Pages.Util.Links as Links
import Util.HttpUtil as HttpUtil


fetchMeal : FlagsWithJWT -> MealId -> Cmd Msg
fetchMeal flags mealId =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Links.backendPage flags.configuration [ "meal", mealId ] []
        , expect = HttpUtil.expectJson GotFetchMealResponse decoderMeal
        }


fetchMealEntries : FlagsWithJWT -> MealId -> Cmd Msg
fetchMealEntries flags mealId =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Links.backendPage flags.configuration [ "meal", mealId, "entry", "all" ] []
        , expect = HttpUtil.expectJson GotFetchMealEntriesResponse (Decode.list decoderMealEntry)
        }


fetchRecipes : { configuration : Configuration, jwt : JWT } -> Cmd Msg
fetchRecipes flags =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Links.backendPage flags.configuration [ "recipe", "all" ] []
        , expect = HttpUtil.expectJson GotFetchRecipesResponse (Decode.list decoderRecipe)
        }


saveMealEntry : FlagsWithJWT -> MealEntryUpdate -> Cmd Msg
saveMealEntry flags mealEntryUpdate =
    HttpUtil.patchJsonWithJWT
        flags.jwt
        { url = Links.backendPage flags.configuration [ "meal", "entry", "update" ] []
        , body = encoderMealEntryUpdate mealEntryUpdate
        , expect = HttpUtil.expectJson GotSaveMealEntryResponse decoderMealEntry
        }


deleteMealEntry : FlagsWithJWT -> MealEntryId -> Cmd Msg
deleteMealEntry fs mealEntryId =
    HttpUtil.deleteWithJWT fs.jwt
        { url = Links.backendPage fs.configuration [ "meal", "entry", "delete", mealEntryId ] []
        , expect = HttpUtil.expectWhatever (GotDeleteMealEntryResponse mealEntryId)
        }


type alias AddMealEntryParams =
    { configuration : Configuration
    , jwt : JWT
    , mealEntryCreation : MealEntryCreation
    }


addMealEntry : AddMealEntryParams -> Cmd Msg
addMealEntry ps =
    HttpUtil.postJsonWithJWT ps.jwt
        { url = Links.backendPage ps.configuration [ "meal", "entry", "create" ] []
        , body = encoderMealEntryCreation ps.mealEntryCreation
        , expect = HttpUtil.expectJson GotAddMealEntryResponse decoderMealEntry
        }
