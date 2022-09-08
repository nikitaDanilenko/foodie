module Pages.Meals.MealCreationClientInput exposing (..)

import Api.Types.MealCreation exposing (MealCreation)
import Api.Types.SimpleDate exposing (SimpleDate)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias MealCreationClientInput =
    { date : SimpleDate
    , name : Maybe String
    , amount : ValidatedInput Float
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
    , amount = ValidatedInput.positive
    }


lenses :
    { date : Lens MealCreationClientInput SimpleDate
    , name : Lens MealCreationClientInput (Maybe String)
    , amount : Lens MealCreationClientInput (ValidatedInput Float)
    }
lenses =
    { date = Lens .date (\b a -> { a | date = b })
    , name = Lens .name (\b a -> { a | name = b })
    , amount = Lens .amount (\b a -> { a | amount = b })
    }


toCreation : MealCreationClientInput -> MealCreation
toCreation input =
    { date = input.date
    , name = input.name
    , amount = input.amount.value
    }
