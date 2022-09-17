module Pages.Recipes.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { jwt : Bool
    , recipes : Bool
    }


initial : Status
initial =
    { jwt = False
    , recipes = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.jwt
        , status.recipes
        ]


lenses :
    { jwt : Lens Status Bool
    , recipes : Lens Status Bool
    }
lenses =
    { jwt = Lens .jwt (\b a -> { a | jwt = b })
    , recipes = Lens .recipes (\b a -> { a | recipes = b })
    }
