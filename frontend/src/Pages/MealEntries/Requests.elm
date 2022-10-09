module Pages.MealEntries.Requests exposing
    ( AddMealEntryParams
    , addMealEntry
    , deleteMealEntry
    , fetchMeal
    , fetchMealEntries
    , fetchRecipes
    , saveMealEntry
    )

import Addresses.Backend
import Api.Auxiliary exposing (JWT, MealEntryId, MealId, RecipeId)
import Api.Types.Meal exposing (decoderMeal)
import Api.Types.MealEntry exposing (MealEntry, decoderMealEntry)
import Api.Types.MealEntryCreation exposing (MealEntryCreation, encoderMealEntryCreation)
import Api.Types.MealEntryUpdate exposing (MealEntryUpdate, encoderMealEntryUpdate)
import Api.Types.Recipe exposing (Recipe, decoderRecipe)
import Configuration exposing (Configuration)
import Http
import Json.Decode as Decode
import Pages.MealEntries.Page exposing (Msg(..), RecipeMap)
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Util.HttpUtil as HttpUtil


fetchMeal : FlagsWithJWT -> MealId -> Cmd Msg
fetchMeal flags mealId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.meals.single mealId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson GotFetchMealResponse decoderMeal
        }


fetchMealEntries : FlagsWithJWT -> MealId -> Cmd Msg
fetchMealEntries flags mealId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.meals.entries.allOf mealId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson GotFetchMealEntriesResponse (Decode.list decoderMealEntry)
        }


fetchRecipes : FlagsWithJWT -> Cmd Msg
fetchRecipes flags =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.recipes.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson GotFetchRecipesResponse (Decode.list decoderRecipe)
        }


saveMealEntry : FlagsWithJWT -> MealEntryUpdate -> Cmd Msg
saveMealEntry flags mealEntryUpdate =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.meals.entries.update
        { body = encoderMealEntryUpdate mealEntryUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson GotSaveMealEntryResponse decoderMealEntry
        }


deleteMealEntry : FlagsWithJWT -> MealEntryId -> Cmd Msg
deleteMealEntry fs mealEntryId =
    HttpUtil.runPatternWithJwt
        fs
        (Addresses.Backend.meals.delete mealEntryId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (GotDeleteMealEntryResponse mealEntryId)
        }


type alias AddMealEntryParams =
    { configuration : Configuration
    , jwt : JWT
    , mealEntryCreation : MealEntryCreation
    }


addMealEntry : AddMealEntryParams -> Cmd Msg
addMealEntry ps =
    HttpUtil.runPatternWithJwt
        { configuration = ps.configuration
        , jwt = ps.jwt
        }
        Addresses.Backend.meals.entries.create
        { body = encoderMealEntryCreation ps.mealEntryCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson GotAddMealEntryResponse decoderMealEntry
        }
