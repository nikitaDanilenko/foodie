module Pages.Recipes.RecipeUpdateClientInput exposing (..)

import Api.Types.Recipe exposing (Recipe)
import Api.Types.RecipeUpdate exposing (RecipeUpdate)
import Api.Types.UUID exposing (UUID)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias RecipeUpdateClientInput =
    { id : UUID
    , name : ValidatedInput String
    , description : Maybe String
    , numberOfServings : ValidatedInput Float
    }


lenses :
    { name : Lens RecipeUpdateClientInput (ValidatedInput String)
    , description : Lens RecipeUpdateClientInput (Maybe String)
    , numberOfServings : Lens RecipeUpdateClientInput (ValidatedInput Float)
    }
lenses =
    { name = Lens .name (\b a -> { a | name = b })
    , description = Lens .description (\b a -> { a | description = b })
    , numberOfServings = Lens .numberOfServings (\b a -> { a | numberOfServings = b })
    }


from : Recipe -> RecipeUpdateClientInput
from recipe =
    { id = recipe.id
    , name =
        ValidatedInput.nonEmptyString
            |> ValidatedInput.lenses.value.set recipe.name
            |> ValidatedInput.lenses.text.set recipe.name
    , description = recipe.description
    , numberOfServings =
        ValidatedInput.positive
            |> ValidatedInput.lenses.value.set recipe.numberOfServings
            |> ValidatedInput.lenses.text.set (recipe.numberOfServings |> String.fromFloat)
    }


to : RecipeUpdateClientInput -> RecipeUpdate
to input =
    { id = input.id
    , name = input.name.value
    , description = input.description
    , numberOfServings = input.numberOfServings.value
    }
