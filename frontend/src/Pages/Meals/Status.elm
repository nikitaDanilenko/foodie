module Pages.Meals.Status exposing (..)

import Monocle.Lens exposing (Lens)
type alias Status =
    { jwt : Bool
    , meals : Bool
    }


initial : Status
initial =
    { jwt = False
    , meals = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.jwt
        , status.meals
        ]


lenses :
    { jwt : Lens Status Bool
    , meals : Lens Status Bool
    }
lenses =
    { jwt = Lens .jwt (\b a -> { a | jwt = b })
    , meals = Lens .meals (\b a -> { a | meals = b })
    }