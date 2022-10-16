module Pages.ReferenceNutrients.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { nutrients : Bool
    , referenceNutrients : Bool
    }


initial : Status
initial =
    { nutrients = False
    , referenceNutrients = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.nutrients
        , status.referenceNutrients
        ]


lenses :
    { nutrients : Lens Status Bool
    , referenceNutrients : Lens Status Bool
    }
lenses =
    { nutrients = Lens .nutrients (\b a -> { a | nutrients = b })
    , referenceNutrients = Lens .referenceNutrients (\b a -> { a | referenceNutrients = b })
    }
