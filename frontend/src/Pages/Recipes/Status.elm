module Pages.Recipes.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { recipes : Bool
    }


initial : Status
initial =
    { recipes = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.recipes
        ]


lenses :
    { recipes : Lens Status Bool
    }
lenses =
    { recipes = Lens .recipes (\b a -> { a | recipes = b })
    }
