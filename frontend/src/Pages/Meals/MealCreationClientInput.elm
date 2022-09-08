module Pages.Meals.MealCreationClientInput exposing (..)

import Api.Types.MealCreation exposing (MealCreation)
import Api.Types.SimpleDate exposing (SimpleDate)
import Monocle.Lens exposing (Lens)


type alias MealCreationClientInput =
    { date : SimpleDate
    , name : Maybe String
    }


default : MealCreationClientInput
default =
    { date =
        { date =
            { year = 2022
            , month = 1
            , day = 1
            }
        , time = Nothing
        }
    , name = Nothing
    }


lenses :
    { date : Lens MealCreationClientInput SimpleDate
    , name : Lens MealCreationClientInput (Maybe String)
    }
lenses =
    { date = Lens .date (\b a -> { a | date = b })
    , name = Lens .name (\b a -> { a | name = b })
    }


toCreation : MealCreationClientInput -> MealCreation
toCreation input =
    { date = input.date
    , name = input.name
    }
