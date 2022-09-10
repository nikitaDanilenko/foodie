module Pages.Meals.Page exposing (..)

import Api.Auxiliary exposing (JWT, MealId)
import Api.Types.Meal exposing (Meal)
import Api.Types.MealUpdate exposing (MealUpdate)
import Configuration exposing (Configuration)
import Either exposing (Either)
import Http exposing (Error)
import Monocle.Lens exposing (Lens)
import Pages.Meals.MealCreationClientInput exposing (MealCreationClientInput)
import Util.Editing exposing (Editing)
import Util.LensUtil as LensUtil


type alias Model =
    { flagsWithJWT : FlagsWithJWT
    , meals : List MealOrUpdate
    , mealsToAdd : List MealCreationClientInput
    }


type alias MealOrUpdate =
    Either Meal (Editing Meal MealUpdate)


lenses :
    { jwt : Lens Model JWT
    , meals : Lens Model (List MealOrUpdate)
    , mealsToAdd : Lens Model (List MealCreationClientInput)
    }
lenses =
    { jwt = LensUtil.jwtSubLens
    , meals = Lens .meals (\b a -> { a | meals = b })
    , mealsToAdd = Lens .mealsToAdd (\b a -> { a | mealsToAdd = b })
    }


type alias Flags =
    { configuration : Configuration
    , jwt : Maybe String
    }


type alias FlagsWithJWT =
    { configuration : Configuration
    , jwt : String
    }


type Msg
    = CreateMeal
    | GotCreateMealResponse (Result Error Meal)
    | UpdateMeal MealUpdate
    | SaveMealEdit MealId
    | GotSaveMealResponse (Result Error Meal)
    | EnterEditMeal MealId
    | ExitEditMealAt MealId
    | DeleteMeal MealId
    | GotDeleteMealResponse MealId (Result Error ())
    | GotFetchMealsResponse (Result Error (List Meal))
    | UpdateJWT String
