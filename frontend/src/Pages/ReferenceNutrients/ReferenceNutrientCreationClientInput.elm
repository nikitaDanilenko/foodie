module Pages.ReferenceNutrients.ReferenceNutrientCreationClientInput exposing (..)

import Api.Auxiliary exposing (MealId, NutrientCode, RecipeId)
import Api.Types.ReferenceNutrientCreation exposing (ReferenceNutrientCreation)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias ReferenceNutrientCreationClientInput =
    { nutrientCode : NutrientCode
    , amount : ValidatedInput Float
    }


lenses : { amount : Lens ReferenceNutrientCreationClientInput (ValidatedInput Float) }
lenses =
    { amount = Lens .amount (\b a -> { a | amount = b })
    }


default : NutrientCode -> ReferenceNutrientCreationClientInput
default nutrientCode =
    { nutrientCode = nutrientCode
    , amount = ValidatedInput.positive
    }


toCreation : ReferenceNutrientCreationClientInput -> ReferenceNutrientCreation
toCreation input =
    { nutrientCode = input.nutrientCode
    , amount = input.amount.value
    }
