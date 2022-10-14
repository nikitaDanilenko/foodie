module Pages.Meals.MealCreationClientInput exposing (..)

import Api.Types.MealCreation exposing (MealCreation)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)
import Pages.Util.SimpleDateInput as SimpleDateInput exposing (SimpleDateInput)


type alias MealCreationClientInput =
    { date : SimpleDateInput
    , name : Maybe String
    }


default : MealCreationClientInput
default =
    { date = SimpleDateInput.default
    , name = Nothing
    }


lenses :
    { date : Lens MealCreationClientInput SimpleDateInput
    , name : Optional MealCreationClientInput String
    }
lenses =
    { date = Lens .date (\b a -> { a | date = b })
    , name = Optional .name (\b a -> { a | name = Just b |> Maybe.Extra.filter (String.isEmpty >> not) })
    }


toCreation : MealCreationClientInput -> Maybe MealCreation
toCreation input =
    input.date
        |> SimpleDateInput.to
        |> Maybe.map
            (\date ->
                { date = date
                , name = input.name
                }
            )
