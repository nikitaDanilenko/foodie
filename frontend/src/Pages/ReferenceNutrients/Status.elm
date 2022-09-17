module Pages.ReferenceNutrients.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { jwt : Bool
    , nutrients : Bool
    , referenceNutrients : Bool
    }


initial : Status
initial =
    { jwt = False
    , nutrients = False
    , referenceNutrients = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.jwt
        , status.nutrients
        , status.referenceNutrients
        ]


lenses :
    { jwt : Lens Status Bool
    , nutrients : Lens Status Bool
    , referenceNutrients : Lens Status Bool
    }
lenses =
    { jwt = Lens .jwt (\b a -> { a | jwt = b })
    , nutrients = Lens .nutrients (\b a -> { a | nutrients = b })
    , referenceNutrients = Lens .referenceNutrients (\b a -> { a | referenceNutrients = b })
    }
