module Pages.Registration.Request.Page exposing (..)

import Configuration exposing (Configuration)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput exposing (ValidatedInput)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { nickname : ValidatedInput String
    , email : ValidatedInput String
    , configuration : Configuration
    , initialization : Initialization ()
    , mode : Mode
    }


lenses :
    { nickname : Lens Model (ValidatedInput String)
    , email : Lens Model (ValidatedInput String)
    , initialization : Lens Model (Initialization ())
    , mode : Lens Model Mode
    }
lenses =
    { nickname = Lens .nickname (\b a -> { a | nickname = b })
    , email = Lens .email (\b a -> { a | email = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , mode = Lens .mode (\b a -> { a | mode = b })
    }


type Mode
    = Editing
    | Confirmed


type alias Flags =
    { configuration : Configuration
    }


type Msg
    = SetNickname (ValidatedInput String)
    | SetEmail (ValidatedInput String)
    | Request
    | GotRequestResponse (Result Error ())
