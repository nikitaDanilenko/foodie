module Pages.Meals.Requests exposing (createMeal, deleteMeal, fetchMeals, saveMeal)

import Addresses.Backend
import Api.Auxiliary exposing (JWT, MealId)
import Api.Types.Meal exposing (Meal, decoderMeal)
import Api.Types.MealCreation exposing (MealCreation, encoderMealCreation)
import Api.Types.MealUpdate exposing (MealUpdate, encoderMealUpdate)
import Http
import Json.Decode as Decode
import Pages.Meals.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil as HttpUtil


fetchMeals : AuthorizedAccess -> Cmd Page.Msg
fetchMeals authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.meals.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchMealsResponse (Decode.list decoderMeal)
        }


createMeal : AuthorizedAccess -> MealCreation -> Cmd Page.Msg
createMeal authorizedAccess mealCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.meals.create
        { body = encoderMealCreation mealCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotCreateMealResponse decoderMeal
        }


saveMeal : AuthorizedAccess -> MealUpdate -> Cmd Page.Msg
saveMeal authorizedAccess mealUpdate =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.meals.update
        { body = encoderMealUpdate mealUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotSaveMealResponse decoderMeal
        }


deleteMeal : AuthorizedAccess -> MealId -> Cmd Page.Msg
deleteMeal authorizedAccess mealId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.meals.delete mealId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (Page.GotDeleteMealResponse mealId)
        }
