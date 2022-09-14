module Pages.Ingredients.RecipeInfo exposing (..)

import Api.Types.Recipe exposing (Recipe)


type alias RecipeInfo =
    { name : String
    , description : Maybe String
    }


from : Recipe -> RecipeInfo
from recipe =
    { name = recipe.name
    , description = recipe.description
    }
