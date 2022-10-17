module Pages.Overview.Handler exposing (init, update)

import Pages.Overview.Page as Page
import Util.Initialization as Initialization


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , initialization = Initialization.Loading ()
      }
    , Cmd.none
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update _ model =
    ( model, Cmd.none )
