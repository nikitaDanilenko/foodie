module Pages.Registration.Request.Page exposing (..)

import Configuration exposing (Configuration)
import Http exposing (Error)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput exposing (ValidatedInput)
import Util.Initialization exposing (Initialization)


type alias Model =
    { nickname : ValidatedInput String
    , email : ValidatedInput String
    , configuration : Configuration
    , initialization: Initialization ()
    }


lenses :
    { nickname : Lens Model (ValidatedInput String)
    , email : Lens Model (ValidatedInput String)
    , initialization : Lens Model (Initialization ())
    }
lenses =
    { nickname = Lens .nickname (\b a -> { a | nickname = b })
    , email = Lens .email (\b a -> { a | email = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    }


type alias Flags =
    { configuration : Configuration
    }


type Msg
    = SetNickname (ValidatedInput String)
    | SetEmail (ValidatedInput String)
    | Request
    | GotResponse (Result Error ())
    | Back