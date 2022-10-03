module Pages.UserSettings.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { jwt : Bool
    , user : Bool
    }


initial : Status
initial =
    { jwt = False
    , user = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.jwt
        , status.user
        ]


lenses :
    { jwt : Lens Status Bool
    , user : Lens Status Bool
    }
lenses =
    { jwt = Lens .jwt (\b a -> { a | jwt = b })
    , user = Lens .user (\b a -> { a | user = b })
    }
