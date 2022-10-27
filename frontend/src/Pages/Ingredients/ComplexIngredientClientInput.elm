module Pages.Ingredients.ComplexIngredientClientInput exposing (..)

import Api.Auxiliary exposing (ComplexFoodId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexIngredient exposing (ComplexIngredient)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias ComplexIngredientClientInput =
    { complexFoodId : ComplexFoodId
    , factor : ValidatedInput Float
    }


lenses :
    { factor : Lens ComplexIngredientClientInput (ValidatedInput Float)
    }
lenses =
    { factor = Lens .factor (\b a -> { a | factor = b })
    }


from : ComplexIngredient -> ComplexIngredientClientInput
from complexIngredient =
    { complexFoodId = complexIngredient.complexFoodId
    , factor =
        ValidatedInput.positive
            |> ValidatedInput.lenses.value.set complexIngredient.factor
            |> ValidatedInput.lenses.text.set (complexIngredient.factor |> String.fromFloat)
    }


fromFood : ComplexFood -> ComplexIngredientClientInput
fromFood complexFood =
    { complexFoodId = complexFood.recipeId
    , factor = ValidatedInput.positive
    }


to : ComplexIngredientClientInput -> ComplexIngredient
to input =
    { complexFoodId = input.complexFoodId
    , factor = input.factor.value
    }
