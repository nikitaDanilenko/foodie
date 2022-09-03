module Pages.IngredientEditor.IngredientUpdateClientInput exposing (..)

import Api.Types.UUID exposing (UUID)
import Monocle.Lens exposing (Lens)
import Pages.IngredientEditor.AmountUnitClientInput exposing (AmountUnitClientInput)


type alias IngredientUpdateClientInput =
    { ingredientId : UUID
    , amountUnit : AmountUnitClientInput
    }


amountUnit : Lens IngredientUpdateClientInput AmountUnitClientInput
amountUnit =
    Lens .amountUnit (\b a -> { a | amountUnit = b })
