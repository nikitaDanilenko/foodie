module Pages.Ingredients.IngredientUpdateClientInput exposing (..)

import Api.Auxiliary exposing (IngredientId)
import Api.Types.Ingredient exposing (Ingredient)
import Api.Types.IngredientUpdate exposing (IngredientUpdate)
import Monocle.Lens exposing (Lens)
import Pages.Ingredients.AmountUnitClientInput as AmountUnitClientInput exposing (AmountUnitClientInput)


type alias IngredientUpdateClientInput =
    { ingredientId : IngredientId
    , amountUnit : AmountUnitClientInput
    }


lenses :
    { amountUnit : Lens IngredientUpdateClientInput AmountUnitClientInput
    }
lenses =
    { amountUnit =
        Lens .amountUnit (\b a -> { a | amountUnit = b })
    }


from : Ingredient -> IngredientUpdateClientInput
from ingredient =
    { ingredientId = ingredient.id
    , amountUnit = AmountUnitClientInput.from ingredient.amountUnit
    }


to : IngredientUpdateClientInput -> IngredientUpdate
to input =
    { ingredientId = input.ingredientId
    , amountUnit = AmountUnitClientInput.to input.amountUnit
    }
