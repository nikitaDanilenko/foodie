module Pages.Util.AuthorizedAccess exposing (..)

import Api.Auxiliary exposing (JWT)
import Configuration exposing (Configuration)


type alias AuthorizedAccess =
    { configuration : Configuration
    , jwt : JWT
    }


from : { a | configuration : Configuration, jwt : JWT } -> AuthorizedAccess
from x =
    { configuration = x.configuration
    , jwt = x.jwt
    }
