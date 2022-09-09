module Pages.MealEntryEditor.MealInfo exposing (..)

import Api.Types.SimpleDate exposing (SimpleDate)


type alias MealInfo =
    { name : Maybe String
    , date : SimpleDate
    }
