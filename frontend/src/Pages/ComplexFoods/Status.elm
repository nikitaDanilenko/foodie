module Pages.ComplexFoods.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { complexFoods : Bool
    , recipes : Bool
    }


initial : Status
initial =
    { complexFoods = False
    , recipes = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.complexFoods
        , status.recipes
        ]


lenses :
    { complexFoods : Lens Status Bool
    , recipes : Lens Status Bool
    }
lenses =
    { complexFoods = Lens .complexFoods (\b a -> { a | complexFoods = b })
    , recipes = Lens .recipes (\b a -> { a | recipes = b })
    }
