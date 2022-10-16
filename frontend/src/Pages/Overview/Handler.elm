module Pages.Overview.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT)
import Pages.Overview.Page as Page
import Pages.Util.FlagsWithJWT as FlagsWithJWT
import Util.Initialization as Initialization


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { flagsWithJWT = FlagsWithJWT.from flags
      , initialization = Initialization.Loading ()
      }
    , Cmd.none
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.UpdateJWT jwt ->
            updateJWT model jwt


updateJWT : Page.Model -> JWT -> ( Page.Model, Cmd Page.Msg )
updateJWT model jwt =
    ( model
        |> Page.lenses.jwt.set jwt
    , Cmd.none
    )
