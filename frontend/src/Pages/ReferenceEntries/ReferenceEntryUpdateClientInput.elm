module Pages.ReferenceEntries.ReferenceEntryUpdateClientInput exposing (..)

import Api.Auxiliary exposing (NutrientCode, RecipeId, ReferenceMapId)
import Api.Types.ReferenceEntryUpdate exposing (ReferenceEntryUpdate)
import Api.Types.ReferenceNutrient exposing (ReferenceNutrient)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias ReferenceEntryUpdateClientInput =
    { nutrientCode : NutrientCode
    , amount : ValidatedInput Float
    }


lenses : { amount : Lens ReferenceEntryUpdateClientInput (ValidatedInput Float) }
lenses =
    { amount = Lens .amount (\b a -> { a | amount = b })
    }


from : ReferenceNutrient -> ReferenceEntryUpdateClientInput
from referenceNutrient =
    { nutrientCode = referenceNutrient.nutrientCode
    , amount =
        ValidatedInput.positive
            |> ValidatedInput.lenses.value.set referenceNutrient.amount
            |> ValidatedInput.lenses.text.set (referenceNutrient.amount |> String.fromFloat)
    }


to : ReferenceMapId -> ReferenceEntryUpdateClientInput -> ReferenceEntryUpdate
to referenceMapId input =
    { referenceMapId = referenceMapId
    , nutrientCode = input.nutrientCode
    , amount = input.amount.value
    }
