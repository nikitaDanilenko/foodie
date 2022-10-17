module Pages.Meals.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { meals : Bool
    }


initial : Status
initial =
    { meals = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.meals
        ]


lenses :
    { meals : Lens Status Bool
    }
lenses =
    { meals = Lens .meals (\b a -> { a | meals = b })
    }
