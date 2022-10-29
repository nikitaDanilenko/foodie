module Pages.Deletion.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Api.Types.UserIdentifier exposing (UserIdentifier)
import Configuration exposing (Configuration)
import Monocle.Lens exposing (Lens)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { deletionJWT : JWT
    , userIdentifier : UserIdentifier
    , configuration : Configuration
    , initialization : Initialization ()
    , mode : Mode
    }


lenses :
    { initialization : Lens Model (Initialization ())
    , mode : Lens Model Mode
    }
lenses =
    { initialization = Lens .initialization (\b a -> { a | initialization = b })
    , mode = Lens .mode (\b a -> { a | mode = b })
    }


type Mode
    = Checking
    | Confirmed


type alias Flags =
    { configuration : Configuration
    , userIdentifier : UserIdentifier
    , deletionJWT : JWT
    }


type Msg
    = Confirm
    | GotConfirmResponse (Result Error ())
