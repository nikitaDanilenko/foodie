module Pages.Overview.Page exposing (..)

import Monocle.Lens exposing (Lens)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , initialization : Initialization ()
    }


lenses :
    { initialization : Lens Model (Initialization ())
    }
lenses =
    { initialization = Lens .initialization (\b a -> { a | initialization = b })
    }


type alias Msg =
    ()


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }
