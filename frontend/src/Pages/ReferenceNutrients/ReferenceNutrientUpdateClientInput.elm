module Pages.ReferenceNutrients.ReferenceNutrientUpdateClientInput exposing (..)

import Api.Auxiliary exposing (NutrientCode, RecipeId)
import Api.Types.ReferenceNutrient exposing (ReferenceNutrient)
import Api.Types.ReferenceNutrientUpdate exposing (ReferenceNutrientUpdate)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias ReferenceNutrientUpdateClientInput =
    { nutrientCode : NutrientCode
    , amount : ValidatedInput Float
    }


lenses : { amount : Lens ReferenceNutrientUpdateClientInput (ValidatedInput Float) }
lenses =
    { amount = Lens .amount (\b a -> { a | amount = b })
    }


from : ReferenceNutrient -> ReferenceNutrientUpdateClientInput
from referenceNutrient =
    { nutrientCode = referenceNutrient.nutrientCode
    , amount =
        ValidatedInput.positive
            |> ValidatedInput.lenses.value.set referenceNutrient.amount
            |> ValidatedInput.lenses.text.set (referenceNutrient.amount |> String.fromFloat)
    }


to : ReferenceNutrientUpdateClientInput -> ReferenceNutrientUpdate
to input =
    { nutrientCode = input.nutrientCode
    , amount = input.amount.value
    }
