module Pages.ReferenceEntries.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { nutrients : Bool
    , referenceMap : Bool
    , referenceEntries : Bool
    }


initial : Status
initial =
    { nutrients = False
    , referenceMap = False
    , referenceEntries = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.nutrients
        , status.referenceMap
        , status.referenceEntries
        ]


lenses :
    { nutrients : Lens Status Bool
    , referenceMap : Lens Status Bool
    , referenceEntries : Lens Status Bool
    }
lenses =
    { nutrients = Lens .nutrients (\b a -> { a | nutrients = b })
    , referenceMap = Lens .referenceMap (\b a -> { a | referenceMap = b })
    , referenceEntries = Lens .referenceEntries (\b a -> { a | referenceEntries = b })
    }
