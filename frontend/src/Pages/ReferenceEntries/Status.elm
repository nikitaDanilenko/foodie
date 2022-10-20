module Pages.ReferenceEntries.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { nutrients : Bool
    , referenceEntries : Bool
    }


initial : Status
initial =
    { nutrients = False
    , referenceEntries = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.nutrients
        , status.referenceEntries
        ]


lenses :
    { nutrients : Lens Status Bool
    , referenceEntries : Lens Status Bool
    }
lenses =
    { nutrients = Lens .nutrients (\b a -> { a | nutrients = b })
    , referenceEntries = Lens .referenceEntries (\b a -> { a | referenceEntries = b })
    }
