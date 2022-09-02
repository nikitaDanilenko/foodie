module Api.Lenses.IngredientUpdateLens exposing (..)

import Api.Types.AmountUnit exposing (AmountUnit)
import Api.Types.IngredientUpdate exposing (IngredientUpdate)
import Monocle.Lens exposing (Lens)


amountUnit : Lens IngredientUpdate AmountUnit
amountUnit =
    Lens .amountUnit (\b a -> { a | amountUnit = b })
