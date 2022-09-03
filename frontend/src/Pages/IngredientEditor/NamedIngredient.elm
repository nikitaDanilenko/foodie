module Pages.IngredientEditor.NamedIngredient exposing (..)

import Api.Types.Ingredient exposing (Ingredient)
import Monocle.Lens exposing (Lens)


type alias NamedIngredient =
    { ingredient : Ingredient
    , name : String
    }


ingredient : Lens NamedIngredient Ingredient
ingredient =
    Lens .ingredient (\b a -> { a | ingredient = b })


name : Lens NamedIngredient String
name =
    Lens .name (\b a -> { a | name = b })
