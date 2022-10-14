module Pages.Meals.MealUpdateClientInput exposing (..)

import Api.Types.Meal exposing (Meal)
import Api.Types.MealUpdate exposing (MealUpdate)
import Api.Types.UUID exposing (UUID)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)
import Pages.Util.SimpleDateInput as SimpleDateInput exposing (SimpleDateInput)


type alias MealUpdateClientInput =
    { id : UUID
    , date : SimpleDateInput
    , name : Maybe String
    }


lenses :
    { date : Lens MealUpdateClientInput SimpleDateInput
    , name : Optional MealUpdateClientInput String
    }
lenses =
    { date = Lens .date (\b a -> { a | date = b })
    , name = Optional .name (\b a -> { a | name = Just b |> Maybe.Extra.filter (String.isEmpty >> not) })
    }


from : Meal -> MealUpdateClientInput
from meal =
    { id = meal.id
    , date = meal.date |> SimpleDateInput.from
    , name = meal.name
    }


to : MealUpdateClientInput -> Maybe MealUpdate
to input =
    input.date
        |> SimpleDateInput.to
        |> Maybe.map
            (\simpleDate ->
                { id = input.id
                , date = simpleDate
                , name = input.name
                }
            )
