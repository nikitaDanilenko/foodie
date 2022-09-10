module Pages.Overview.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Configuration exposing (Configuration)
import Monocle.Lens exposing (Lens)
import Util.LensUtil as LensUtil


type alias Model =
    { flagsWithJWT : FlagsWithJWT
    }


lenses :
    { jwt : Lens Model JWT
    }
lenses =
    { jwt = LensUtil.jwtSubLens
    }

type Msg
    = Recipes
    | Meals
    | Statistics
    | UpdateJWT String

type alias Flags =
    { configuration : Configuration
    , jwt : Maybe String
    }


type alias FlagsWithJWT =
    { configuration : Configuration
    , jwt : String
    }
