module Pages.Statistics.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { referenceTrees : Bool
    }


initial : Status
initial =
    { referenceTrees = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.referenceTrees
        ]


lenses :
    { referenceTrees : Lens Status Bool
    }
lenses =
    { referenceTrees = Lens .referenceTrees (\b a -> { a | referenceTrees = b })
    }
