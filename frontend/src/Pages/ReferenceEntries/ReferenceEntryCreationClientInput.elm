module Pages.ReferenceEntries.ReferenceEntryCreationClientInput exposing (..)

import Api.Auxiliary exposing (MealId, NutrientCode, RecipeId, ReferenceMapId)
import Api.Types.ReferenceEntryCreation exposing (ReferenceEntryCreation)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias ReferenceEntryCreationClientInput =
    { nutrientCode : NutrientCode
    , amount : ValidatedInput Float
    }


lenses : { amount : Lens ReferenceEntryCreationClientInput (ValidatedInput Float) }
lenses =
    { amount = Lens .amount (\b a -> { a | amount = b })
    }


default : NutrientCode -> ReferenceEntryCreationClientInput
default nutrientCode =
    { nutrientCode = nutrientCode
    , amount = ValidatedInput.positive
    }


toCreation : ReferenceMapId -> ReferenceEntryCreationClientInput -> ReferenceEntryCreation
toCreation referenceMapId input =
    { referenceMapId = referenceMapId
    , nutrientCode = input.nutrientCode
    , amount = input.amount.value
    }
