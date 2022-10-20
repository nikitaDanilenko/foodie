module Pages.ReferenceMaps.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { referenceMaps : Bool
    }


initial : Status
initial =
    { referenceMaps = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.referenceMaps
        ]


lenses :
    { referenceMaps : Lens Status Bool
    }
lenses =
    { referenceMaps = Lens .referenceMaps (\b a -> { a | referenceMaps = b })
    }
