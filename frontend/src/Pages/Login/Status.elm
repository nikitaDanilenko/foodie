module Pages.Login.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { jwt : Bool
    }


initial : Status
initial =
    { jwt = False }


isFinished : Status -> Bool
isFinished status =
    status.jwt


lenses : { jwt : Lens Status Bool }
lenses =
    { jwt = Lens .jwt (\b a -> { a | jwt = b })
    }
