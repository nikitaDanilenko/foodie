module Pages.Recipes.RecipeUpdateClientInput exposing (..)

import Api.Types.Recipe exposing (Recipe)
import Api.Types.RecipeUpdate exposing (RecipeUpdate)
import Api.Types.UUID exposing (UUID)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias RecipeUpdateClientInput =
    { id : UUID
    , name : String
    , description : Maybe String
    , numberOfServings : ValidatedInput Float
    }


lenses :
    { name : Lens RecipeUpdateClientInput String
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
    , name = recipe.name
    , description = recipe.description
    , numberOfServings = ValidatedInput.positive |> ValidatedInput.value.set recipe.numberOfServings
    }


to : RecipeUpdateClientInput -> RecipeUpdate
to input =
    { id = input.id
    , name = input.name
    , description = input.description
    , numberOfServings = input.numberOfServings.value
    }