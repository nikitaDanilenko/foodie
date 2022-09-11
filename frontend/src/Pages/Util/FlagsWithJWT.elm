module Pages.Util.FlagsWithJWT exposing (..)

import Api.Auxiliary exposing (JWT)
import Configuration exposing (Configuration)


type alias FlagsWithJWT =
    { configuration : Configuration
    , jwt : JWT
    }
