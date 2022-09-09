module Pages.MealEntryEditor.Requests exposing
    ( AddMealEntryParams
    , addMealEntry
    , deleteMealEntry
    , fetchMeal
    , fetchMealEntries
    , fetchRecipes
    , saveMealEntry
    )

import Api.Auxiliary exposing (JWT, MealEntryId, RecipeId)
import Api.Types.Meal exposing (decoderMeal)
import Api.Types.MealEntry exposing (MealEntry, decoderMealEntry)
import Api.Types.MealEntryCreation exposing (MealEntryCreation, encoderMealEntryCreation)
import Api.Types.MealEntryUpdate exposing (MealEntryUpdate, encoderMealEntryUpdate)
import Api.Types.Recipe exposing (Recipe, decoderRecipe)
import Configuration exposing (Configuration)
import Json.Decode as Decode
import Pages.MealEntryEditor.Page exposing (FlagsWithJWT, Msg(..), RecipeMap)
import Url.Builder
import Util.HttpUtil as HttpUtil


fetchMeal : FlagsWithJWT -> Cmd Msg
fetchMeal flags =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "meal", flags.mealId ] []
        , expect = HttpUtil.expectJson GotFetchMealResponse decoderMeal
        }


fetchMealEntries : FlagsWithJWT -> Cmd Msg
fetchMealEntries flags =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "meal", flags.mealId, "meal-entries" ] []
        , expect = HttpUtil.expectJson GotFetchMealEntriesResponse (Decode.list decoderMealEntry)
        }


fetchRecipes : { configuration : Configuration, jwt : JWT } -> Cmd Msg
fetchRecipes flags =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "recipe", "all" ] []
        , expect = HttpUtil.expectJson GotFetchRecipesResponse (Decode.list decoderRecipe)
        }


saveMealEntry : FlagsWithJWT -> MealEntryUpdate -> Cmd Msg
saveMealEntry flags mealEntryUpdate =
    HttpUtil.patchJsonWithJWT
        flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "meal", "update-meal-entry" ] []
        , body = encoderMealEntryUpdate mealEntryUpdate
        , expect = HttpUtil.expectJson GotSaveMealEntryResponse decoderMealEntry
        }


deleteMealEntry : FlagsWithJWT -> MealEntryId -> Cmd Msg
deleteMealEntry fs mealEntryId =
    HttpUtil.deleteWithJWT fs.jwt
        { url = Url.Builder.relative [ fs.configuration.backendURL, "meal", "delete-meal-entry", mealEntryId ] []
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
        { url = Url.Builder.relative [ ps.configuration.backendURL, "meal", "add-meal-entry" ] []
        , body = encoderMealEntryCreation ps.mealEntryCreation
        , expect = HttpUtil.expectJson GotAddMealEntryResponse decoderMealEntry
        }
