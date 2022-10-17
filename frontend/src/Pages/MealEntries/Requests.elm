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
import Http
import Json.Decode as Decode
import Pages.MealEntries.Page exposing (Msg(..), RecipeMap)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil as HttpUtil


fetchMeal : AuthorizedAccess -> MealId -> Cmd Msg
fetchMeal authorizedAccess mealId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.single mealId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson GotFetchMealResponse decoderMeal
        }


fetchMealEntries : AuthorizedAccess -> MealId -> Cmd Msg
fetchMealEntries authorizedAccess mealId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.entries.allOf mealId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson GotFetchMealEntriesResponse (Decode.list decoderMealEntry)
        }


fetchRecipes : AuthorizedAccess -> Cmd Msg
fetchRecipes flags =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.recipes.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson GotFetchRecipesResponse (Decode.list decoderRecipe)
        }


saveMealEntry : AuthorizedAccess -> MealEntryUpdate -> Cmd Msg
saveMealEntry authorizedAccess mealEntryUpdate =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.meals.entries.update
        { body = encoderMealEntryUpdate mealEntryUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson GotSaveMealEntryResponse decoderMealEntry
        }


deleteMealEntry : AuthorizedAccess -> MealEntryId -> Cmd Msg
deleteMealEntry authorizedAccess mealEntryId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.delete mealEntryId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (GotDeleteMealEntryResponse mealEntryId)
        }


type alias AddMealEntryParams =
    { authorizedAccess : AuthorizedAccess
    , mealEntryCreation : MealEntryCreation
    }


addMealEntry : AddMealEntryParams -> Cmd Msg
addMealEntry ps =
    HttpUtil.runPatternWithJwt
        ps.authorizedAccess
        Addresses.Backend.meals.entries.create
        { body = encoderMealEntryCreation ps.mealEntryCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson GotAddMealEntryResponse decoderMealEntry
        }
