module Pages.Login.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Api.Types.Credentials exposing (Credentials)
import Configuration exposing (Configuration)
import Http exposing (Error)
import Monocle.Lens exposing (Lens)
import Pages.Login.Status exposing (Status)
import Util.Initialization exposing (Initialization)


type alias Model =
    { credentials : Credentials
    , initialization : Initialization Status
    , configuration : Configuration
    }


lenses :
    { credentials : Lens Model Credentials
    , initialization : Lens Model (Initialization Status)
    }
lenses =
    { credentials = Lens .credentials (\b a -> { a | credentials = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    }


type alias Flags =
    { configuration : Configuration
    }


type Msg
    = SetNickname String
    | SetPassword String
    | Login
    | GotResponse (Result Error JWT)
