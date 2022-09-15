module Pages.Meals.Requests exposing (createMeal, deleteMeal, fetchMeals, saveMeal)

import Api.Auxiliary exposing (JWT, MealId)
import Api.Types.Meal exposing (Meal, decoderMeal)
import Api.Types.MealCreation exposing (MealCreation, encoderMealCreation)
import Api.Types.MealUpdate exposing (MealUpdate, encoderMealUpdate)
import Configuration exposing (Configuration)
import Json.Decode as Decode
import Pages.Meals.Page as Page
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Url.Builder
import Util.HttpUtil as HttpUtil


fetchMeals : FlagsWithJWT -> Cmd Page.Msg
fetchMeals flags =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "meal", "all" ] []
        , expect = HttpUtil.expectJson Page.GotFetchMealsResponse (Decode.list decoderMeal)
        }


createMeal : FlagsWithJWT -> MealCreation -> Cmd Page.Msg
createMeal flags mealCreation =
    HttpUtil.postJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "meal", "create" ] []
        , body = encoderMealCreation mealCreation
        , expect = HttpUtil.expectJson Page.GotCreateMealResponse decoderMeal
        }


saveMeal : FlagsWithJWT -> MealUpdate -> Cmd Page.Msg
saveMeal flags mealUpdate =
    HttpUtil.patchJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "meal", "update" ] []
        , body = encoderMealUpdate mealUpdate
        , expect = HttpUtil.expectJson Page.GotSaveMealResponse decoderMeal
        }


deleteMeal : FlagsWithJWT -> MealId -> Cmd Page.Msg
deleteMeal flags mealId =
    HttpUtil.deleteWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "meal", "delete", mealId ] []
        , expect = HttpUtil.expectWhatever (Page.GotDeleteMealResponse mealId)
        }
