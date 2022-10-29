module Pages.Registration.Confirm.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Api.Types.UserIdentifier exposing (UserIdentifier)
import Configuration exposing (Configuration)
import Monocle.Lens exposing (Lens)
import Pages.Util.ComplementInput exposing (ComplementInput)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { userIdentifier : UserIdentifier
    , complementInput : ComplementInput
    , configuration : Configuration
    , initialization : Initialization ()
    , registrationJWT : JWT
    , mode : Mode
    }


lenses :
    { complementInput : Lens Model ComplementInput
    , initialization : Lens Model (Initialization ())
    , mode : Lens Model Mode
    }
lenses =
    { complementInput = Lens .complementInput (\b a -> { a | complementInput = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , mode = Lens .mode (\b a -> { a | mode = b })
    }


type Mode
    = Editing
    | Confirmed


type alias Flags =
    { configuration : Configuration
    , userIdentifier : UserIdentifier
    , registrationJWT : JWT
    }


type Msg
    = SetComplementInput ComplementInput
    | Request
    | GotResponse (Result Error ())
