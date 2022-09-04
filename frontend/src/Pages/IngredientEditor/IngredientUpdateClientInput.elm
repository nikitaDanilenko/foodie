module Pages.IngredientEditor.IngredientUpdateClientInput exposing (..)

import Api.Types.Ingredient exposing (Ingredient)
import Api.Types.UUID exposing (UUID)
import Monocle.Lens exposing (Lens)
import Pages.IngredientEditor.AmountUnitClientInput as AmountUnitClientInput exposing (AmountUnitClientInput)


type alias IngredientUpdateClientInput =
    { ingredientId : UUID
    , amountUnit : AmountUnitClientInput
    }


amountUnit : Lens IngredientUpdateClientInput AmountUnitClientInput
amountUnit =
    Lens .amountUnit (\b a -> { a | amountUnit = b })


from : Ingredient -> IngredientUpdateClientInput
from ingredient =
    { ingredientId = ingredient.id
    , amountUnit = AmountUnitClientInput.from ingredient.amountUnit
    }
