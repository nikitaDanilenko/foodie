module Pages.Registration.Confirm.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Api.Types.UserIdentifier exposing (UserIdentifier)
import Configuration exposing (Configuration)
import Http exposing (Error)
import Monocle.Lens exposing (Lens)
import Util.Initialization exposing (Initialization)


type alias Model =
    { userIdentifier : UserIdentifier
    , displayName : Maybe String
    , password1 : String
    , password2 : String
    , configuration : Configuration
    , initialization : Initialization ()
    , registrationJWT : JWT
    }


lenses :
    { displayName : Lens Model (Maybe String)
    , password1 : Lens Model String
    , password2 : Lens Model String
    , initialization : Lens Model (Initialization ())
    }
lenses =
    { displayName = Lens .displayName (\b a -> { a | displayName = b })
    , password1 = Lens .password1 (\b a -> { a | password1 = b })
    , password2 = Lens .password2 (\b a -> { a | password2 = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    }


type alias Flags =
    { configuration : Configuration
    , userIdentifier : UserIdentifier
    , registrationJWT: JWT
    }


type Msg
    = SetDisplayName (Maybe String)
    | SetPassword1 String
    | SetPassword2 String
    | Request
    | GotResponse (Result Error ())
    | NavigateToMain
