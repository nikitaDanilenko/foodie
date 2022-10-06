module Pages.Recovery.Request.Page exposing (..)

import Api.Auxiliary exposing (UserId)
import Api.Types.User exposing (User)
import Configuration exposing (Configuration)
import Http exposing (Error)
import Monocle.Lens exposing (Lens)
import Util.Initialization exposing (Initialization)


type alias Model =
    { configuration : Configuration
    , users : List User
    , searchString : String
    , initialization : Initialization ()
    , mode : Mode
    }


type Mode
    = Initial
    | Requesting
    | Requested


lenses :
    { users : Lens Model (List User)
    , searchString : Lens Model String
    , initialization : Lens Model (Initialization ())
    , mode : Lens Model Mode
    }
lenses =
    { users = Lens .users (\b a -> { a | users = b })
    , searchString = Lens .searchString (\b a -> { a | searchString = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , mode = Lens .mode (\b a -> { a | mode = b })
    }


type alias Flags =
    { configuration : Configuration
    }


type Msg
    = Find
    | GotFindResponse (Result Error (List User))
    | SetSearchString String
    | RequestRecovery UserId
    | GotRequestRecoveryResponse (Result Error ())
