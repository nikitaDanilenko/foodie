module Pages.Meals.Requests exposing (createMeal, deleteMeal, fetchMeals, saveMeal)

import Api.Auxiliary exposing (JWT, MealId)
import Api.Types.Meal exposing (Meal, decoderMeal)
import Api.Types.MealCreation exposing (encoderMealCreation)
import Api.Types.MealUpdate exposing (MealUpdate, encoderMealUpdate)
import Configuration exposing (Configuration)
import Json.Decode as Decode
import Pages.Meals.MealCreationClientInput as MealCreationClientInput exposing (MealCreationClientInput)
import Pages.Meals.Page as Page
import Url.Builder
import Util.HttpUtil as HttpUtil


fetchMeals : Page.FlagsWithJWT -> Cmd Page.Msg
fetchMeals flags =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "meal", "all" ] []
        , expect = HttpUtil.expectJson Page.GotFetchMealsResponse (Decode.list decoderMeal)
        }


createMeal : Page.FlagsWithJWT -> Cmd Page.Msg
createMeal flags =
    HttpUtil.postJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "meal", "create" ] []
        , body =
            MealCreationClientInput.default
                |> MealCreationClientInput.toCreation
                |> encoderMealCreation
        , expect = HttpUtil.expectJson Page.GotCreateMealResponse decoderMeal
        }


saveMeal : Page.FlagsWithJWT -> MealUpdate -> Cmd Page.Msg
saveMeal flags mealUpdate =
    HttpUtil.patchJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "meal", "update" ] []
        , body = encoderMealUpdate mealUpdate
        , expect = HttpUtil.expectJson Page.GotSaveMealResponse decoderMeal
        }


deleteMeal : Page.FlagsWithJWT -> MealId -> Cmd Page.Msg
deleteMeal flags mealId =
    HttpUtil.deleteWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "meal", "delete", mealId ] []
        , expect = HttpUtil.expectWhatever (Page.GotDeleteMealResponse mealId)
        }
