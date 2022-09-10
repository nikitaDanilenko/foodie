module Pages.Login.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Api.Types.Credentials exposing (Credentials)
import Configuration exposing (Configuration)
import Http exposing (Error)
import Monocle.Lens exposing (Lens)
import Util.TriState exposing (TriState)


type alias Model =
    { credentials : Credentials
    , state : TriState
    , configuration : Configuration
    }


lenses :
    { credentials : Lens Model Credentials
    , state : Lens Model TriState
    }
lenses =
    { credentials = Lens .credentials (\b a -> { a | credentials = b })
    , state = Lens .state (\b a -> { a | state = b })
    }


type alias Flags =
    { configuration : Configuration
    }


type Msg
    = SetNickname String
    | SetPassword String
    | Login
    | GotResponse (Result Error JWT)
