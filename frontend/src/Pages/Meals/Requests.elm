module Pages.Meals.Requests exposing (createMeal, deleteMeal, fetchMeals, saveMeal)

import Addresses.Backend
import Api.Auxiliary exposing (JWT, MealId)
import Api.Types.Meal exposing (Meal, decoderMeal)
import Api.Types.MealCreation exposing (MealCreation, encoderMealCreation)
import Api.Types.MealUpdate exposing (MealUpdate, encoderMealUpdate)
import Http
import Json.Decode as Decode
import Pages.Meals.Page as Page
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Util.HttpUtil as HttpUtil


fetchMeals : FlagsWithJWT -> Cmd Page.Msg
fetchMeals flags =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.meals.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchMealsResponse (Decode.list decoderMeal)
        }


createMeal : FlagsWithJWT -> MealCreation -> Cmd Page.Msg
createMeal flags mealCreation =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.meals.create
        { body = encoderMealCreation mealCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotCreateMealResponse decoderMeal
        }


saveMeal : FlagsWithJWT -> MealUpdate -> Cmd Page.Msg
saveMeal flags mealUpdate =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.meals.update
        { body = encoderMealUpdate mealUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotSaveMealResponse decoderMeal
        }


deleteMeal : FlagsWithJWT -> MealId -> Cmd Page.Msg
deleteMeal flags mealId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.meals.delete mealId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (Page.GotDeleteMealResponse mealId)
        }
