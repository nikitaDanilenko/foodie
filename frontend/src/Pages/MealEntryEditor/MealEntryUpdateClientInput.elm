module Pages.MealEntryEditor.MealEntryUpdateClientInput exposing (..)

import Api.Auxiliary exposing (MealEntryId, RecipeId)
import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.MealEntryUpdate exposing (MealEntryUpdate)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias MealEntryUpdateClientInput =
    { mealEntryId : MealEntryId
    , recipeId : RecipeId
    , factor : ValidatedInput Float
    }


lenses : { factor : Lens MealEntryUpdateClientInput (ValidatedInput Float) }
lenses =
    { factor = Lens .factor (\b a -> { a | factor = b })
    }


from : MealEntry -> MealEntryUpdateClientInput
from mealEntry =
    { mealEntryId = mealEntry.id
    , recipeId = mealEntry.recipeId
    , factor = ValidatedInput.positive |> ValidatedInput.value.set mealEntry.factor
    }


to : MealEntryUpdateClientInput -> MealEntryUpdate
to input =
    { mealEntryId = input.mealEntryId
    , recipeId = input.recipeId
    , factor = input.factor.value
    }
