module Pages.MealEntries.MealEntryCreationClientInput exposing (..)

import Api.Auxiliary exposing (MealId, RecipeId)
import Api.Types.MealEntryCreation exposing (MealEntryCreation)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias MealEntryCreationClientInput =
    { mealId : MealId
    , recipeId : RecipeId
    , numberOfServings : ValidatedInput Float
    }


lenses : { numberOfServings : Lens MealEntryCreationClientInput (ValidatedInput Float) }
lenses =
    { numberOfServings = Lens .numberOfServings (\b a -> { a | numberOfServings = b })
    }


default : MealId -> RecipeId -> MealEntryCreationClientInput
default mealId recipeId =
    { mealId = mealId
    , recipeId = recipeId
    , numberOfServings = ValidatedInput.positive
    }


toCreation : MealEntryCreationClientInput -> MealEntryCreation
toCreation input =
    { mealId = input.mealId
    , recipeId = input.recipeId
    , numberOfServings = input.numberOfServings.value
    }
