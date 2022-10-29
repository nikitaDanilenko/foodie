module Pages.Recovery.Confirm.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Api.Types.UserIdentifier exposing (UserIdentifier)
import Configuration exposing (Configuration)
import Monocle.Lens exposing (Lens)
import Pages.Util.PasswordInput exposing (PasswordInput)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { configuration : Configuration
    , recoveryJwt : JWT
    , userIdentifier : UserIdentifier
    , passwordInput : PasswordInput
    , initialization : Initialization ()
    , mode : Mode
    }


lenses :
    { passwordInput : Lens Model PasswordInput
    , initialization : Lens Model (Initialization ())
    , mode : Lens Model Mode
    }
lenses =
    { passwordInput = Lens .passwordInput (\b a -> { a | passwordInput = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , mode = Lens .mode (\b a -> { a | mode = b })
    }


type Mode
    = Resetting
    | Confirmed


type alias Flags =
    { configuration : Configuration
    , userIdentifier : UserIdentifier
    , recoveryJwt : JWT
    }


type Msg
    = SetPasswordInput PasswordInput
    | Confirm
    | GotConfirmResponse (Result Error ())
