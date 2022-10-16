module Pages.Util.FlagsWithJWT exposing (..)

import Api.Auxiliary exposing (JWT)
import Configuration exposing (Configuration)


type alias FlagsWithJWT =
    { configuration : Configuration
    , jwt : JWT
    }


from : { a | configuration : Configuration, jwt : JWT } -> FlagsWithJWT
from x =
    { configuration = x.configuration
    , jwt = x.jwt
    }
