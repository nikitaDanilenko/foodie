module Pages.Deletion.Confirmation.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Api.Types.UserIdentifier exposing (UserIdentifier)
import Configuration exposing (Configuration)
import Http exposing (Error)
import Monocle.Lens exposing (Lens)
import Util.Initialization exposing (Initialization)


type alias Model =
    { deletionJWT : JWT
    , userIdentifier : UserIdentifier
    , configuration : Configuration
    , initialization : Initialization ()
    }


lenses :
    { initialization : Lens Model (Initialization ())
    }
lenses =
    { initialization = Lens .initialization (\b a -> { a | initialization = b })
    }


type alias Flags =
    { configuration : Configuration
    , userIdentifier : UserIdentifier
    , deletionJWT : JWT
    }


type Msg
    = Confirm
    | GotConfirmResponse (Result Error ())
    | NavigateToMain
