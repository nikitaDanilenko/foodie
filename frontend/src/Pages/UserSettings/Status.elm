module Pages.UserSettings.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { user : Bool
    }


initial : Status
initial =
    { user = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.user
        ]


lenses :
    { user : Lens Status Bool
    }
lenses =
    { user = Lens .user (\b a -> { a | user = b })
    }
