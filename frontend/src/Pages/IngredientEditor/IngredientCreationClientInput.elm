module Pages.IngredientEditor.IngredientCreationClientInput exposing (..)

import Api.Auxiliary exposing (FoodId, MeasureId, RecipeId)
import Api.Types.IngredientCreation exposing (IngredientCreation)
import Monocle.Lens exposing (Lens)
import Pages.IngredientEditor.AmountUnitClientInput as AmountUnitClientInput exposing (AmountUnitClientInput)


type alias IngredientCreationClientInput =
    { recipeId : RecipeId
    , foodId : FoodId
    , amountUnit : AmountUnitClientInput
    }


default : RecipeId -> FoodId -> MeasureId -> IngredientCreationClientInput
default recipeId foodId measureId =
    { recipeId = recipeId
    , foodId = foodId
    , amountUnit = AmountUnitClientInput.default measureId
    }


amountUnit : Lens IngredientCreationClientInput AmountUnitClientInput
amountUnit =
    Lens .amountUnit (\b a -> { a | amountUnit = b })


toCreation : IngredientCreationClientInput -> IngredientCreation
toCreation input =
    { recipeId = input.recipeId
    , foodId = input.foodId
    , amountUnit =
        { factor = input.amountUnit.factor.value
        , measureId = input.amountUnit.measureId
        }
    }
