module Pages.Meals.Model exposing (..)

import Api.Auxiliary exposing (JWT)
import Api.Types.Meal exposing (Meal)
import Api.Types.MealUpdate exposing (MealUpdate)
import Configuration exposing (Configuration)
import Either exposing (Either)
import Monocle.Lens exposing (Lens)
import Pages.Meals.MealCreationClientInput exposing (MealCreationClientInput)
import Util.Editing exposing (Editing)


type alias Model =
    { configuration : Configuration
    , jwt : JWT
    , meals : List MealOrUpdate
    , mealsToAdd : List MealCreationClientInput
    }


type alias MealOrUpdate =
    Either Meal (Editing Meal MealUpdate)


lens :
    { jwt : Lens Model JWT
    , meals : Lens Model (List MealOrUpdate)
    , mealsToAdd : Lens Model (List MealCreationClientInput)
    }
lens =
    { jwt = Lens .jwt (\b a -> { a | jwt = b })
    , meals = Lens .meals (\b a -> { a | meals = b })
    , mealsToAdd = Lens .mealsToAdd (\b a -> { a | mealsToAdd = b })
    }


type alias Flags =
    { configuration : Configuration
    , jwt : Maybe String
    }
