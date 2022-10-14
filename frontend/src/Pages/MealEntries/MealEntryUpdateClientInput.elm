module Pages.MealEntries.MealEntryUpdateClientInput exposing (..)

import Api.Auxiliary exposing (MealEntryId, RecipeId)
import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.MealEntryUpdate exposing (MealEntryUpdate)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias MealEntryUpdateClientInput =
    { mealEntryId : MealEntryId
    , recipeId : RecipeId
    , numberOfServings : ValidatedInput Float
    }


lenses : { numberOfServings : Lens MealEntryUpdateClientInput (ValidatedInput Float) }
lenses =
    { numberOfServings = Lens .numberOfServings (\b a -> { a | numberOfServings = b })
    }


from : MealEntry -> MealEntryUpdateClientInput
from mealEntry =
    { mealEntryId = mealEntry.id
    , recipeId = mealEntry.recipeId
    , numberOfServings =
        ValidatedInput.positive
            |> ValidatedInput.lenses.value.set mealEntry.numberOfServings
            |> ValidatedInput.lenses.text.set (mealEntry.numberOfServings |> String.fromFloat)
    }


to : MealEntryUpdateClientInput -> MealEntryUpdate
to input =
    { mealEntryId = input.mealEntryId
    , recipeId = input.recipeId
    , numberOfServings = input.numberOfServings.value
    }
