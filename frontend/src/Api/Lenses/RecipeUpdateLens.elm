module Api.Lenses.RecipeUpdateLens exposing (..)

import Api.Types.RecipeUpdate exposing (RecipeUpdate)
import Monocle.Lens exposing (Lens)


name : Lens RecipeUpdate String
name =
    Lens .name (\b a -> { a | name = b })


description : Lens RecipeUpdate (Maybe String)
description =
    Lens .description (\b a -> { a | description = b })
