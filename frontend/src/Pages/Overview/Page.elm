module Pages.Overview.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Configuration exposing (Configuration)
import Monocle.Lens exposing (Lens)
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Util.Initialization exposing (Initialization)


type alias Model =
    { flagsWithJWT : FlagsWithJWT
    , initialization : Initialization ()
    }


lenses :
    { initialization : Lens Model (Initialization ())
    }
lenses =
    { initialization = Lens .initialization (\b a -> { a | initialization = b })
    }


type alias Msg =
    ()


type alias Flags =
    { configuration : Configuration
    , jwt : JWT
    }
