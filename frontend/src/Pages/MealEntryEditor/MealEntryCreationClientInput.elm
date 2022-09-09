module Pages.MealEntryEditor.MealEntryCreationClientInput exposing (..)

import Api.Auxiliary exposing (MealId, RecipeId)
import Api.Types.MealEntryCreation exposing (MealEntryCreation)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias MealEntryCreationClientInput =
    { mealId : MealId
    , recipeId : RecipeId
    , factor : ValidatedInput Float
    }


lenses : { factor : Lens MealEntryCreationClientInput (ValidatedInput Float) }
lenses =
    { factor = Lens .factor (\b a -> { a | factor = b })
    }


default : MealId -> RecipeId -> MealEntryCreationClientInput
default mealId recipeId =
    { mealId = mealId
    , recipeId = recipeId
    , factor = ValidatedInput.positive
    }


toCreation : MealEntryCreationClientInput -> MealEntryCreation
toCreation input =
    { mealId = input.mealId
    , recipeId = input.recipeId
    , factor = input.factor.value
    }
