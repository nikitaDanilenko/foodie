module Api.Lenses.MealUpdateLens exposing (..)

import Api.Types.MealUpdate exposing (MealUpdate)
import Api.Types.SimpleDate exposing (SimpleDate)
import Monocle.Lens exposing (Lens)


name : Lens MealUpdate (Maybe String)
name =
    Lens .name (\b a -> { a | name = b })


date : Lens MealUpdate SimpleDate
date =
    Lens .date (\b a -> { a | date = b })
