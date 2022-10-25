module Pages.ComplexFoods.ComplexFoodClientInput exposing (..)

import Api.Auxiliary exposing (RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexFoodUnit exposing (ComplexFoodUnit)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias ComplexFoodClientInput =
    { recipeId : RecipeId
    , amount : ValidatedInput Float
    , unit : ComplexFoodUnit
    }


from : ComplexFood -> ComplexFoodClientInput
from complexFood =
    { recipeId = complexFood.recipeId
    , amount =
        ValidatedInput.positive
            |> ValidatedInput.lenses.value.set complexFood.amount
            |> ValidatedInput.lenses.text.set (complexFood.amount |> String.fromFloat)
    , unit = complexFood.unit
    }


to : ComplexFoodClientInput -> ComplexFood
to input =
    { recipeId = input.recipeId
    , amount = input.amount.value
    , unit = input.unit
    }


lenses :
    { amount : Lens ComplexFoodClientInput (ValidatedInput Float)
    , unit : Lens ComplexFoodClientInput ComplexFoodUnit
    }
lenses =
    { amount = Lens .amount (\b a -> { a | amount = b })
    , unit = Lens .unit (\b a -> { a | unit = b })
    }
