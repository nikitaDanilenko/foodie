module Pages.Overview.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Configuration exposing (Configuration)
import Monocle.Lens exposing (Lens)
import Pages.Overview.Status exposing (Status)
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Util.Initialization exposing (Initialization)
import Util.LensUtil as LensUtil


type alias Model =
    { flagsWithJWT : FlagsWithJWT
    , initialization : Initialization Status
    }


lenses :
    { jwt : Lens Model JWT
    , initialization : Lens Model (Initialization Status)
    }
lenses =
    { jwt = LensUtil.jwtSubLens
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    }


type Msg
    =  UpdateJWT String


type alias Flags =
    { configuration : Configuration
    , jwt : Maybe String
    }
