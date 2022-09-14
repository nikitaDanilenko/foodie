module Pages.MealEntries.MealInfo exposing (..)

import Api.Types.Meal exposing (Meal)
import Api.Types.SimpleDate exposing (SimpleDate)


type alias MealInfo =
    { name : Maybe String
    , date : SimpleDate
    }


from : Meal -> MealInfo
from meal =
    { name = meal.name
    , date = meal.date
    }
