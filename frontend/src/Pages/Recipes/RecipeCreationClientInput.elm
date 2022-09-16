module Pages.Recipes.RecipeCreationClientInput exposing (..)

import Api.Types.RecipeCreation exposing (RecipeCreation)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias RecipeCreationClientInput =
    { name : ValidatedInput String
    , description : Maybe String
    , numberOfServings : ValidatedInput Float
    }


default : RecipeCreationClientInput
default =
    { name = ValidatedInput.nonEmptyString
    , description = Nothing
    , numberOfServings = ValidatedInput.positive
    }


lenses :
    { name : Lens RecipeCreationClientInput (ValidatedInput String)
    , description : Lens RecipeCreationClientInput (Maybe String)
    , numberOfServings : Lens RecipeCreationClientInput (ValidatedInput Float)
    }
lenses =
    { name = Lens .name (\b a -> { a | name = b })
    , description = Lens .description (\b a -> { a | description = b })
    , numberOfServings = Lens .numberOfServings (\b a -> { a | numberOfServings = b })
    }


toCreation : RecipeCreationClientInput -> RecipeCreation
toCreation input =
    { name = input.name.value
    , description = input.description
    , numberOfServings = input.numberOfServings.value
    }
