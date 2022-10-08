module Pages.Overview.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT)
import Pages.Overview.Page as Page
import Pages.Overview.Status as Status
import Pages.Util.InitUtil as InitUtil
import Util.Initialization as Initialization
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    let
        ( jwt, cmd ) =
            InitUtil.fetchIfEmpty flags.jwt
                (always Cmd.none)
    in
    ( { flagsWithJWT =
            { configuration = flags.configuration
            , jwt = jwt
            }
      , initialization = Initialization.Loading (Status.initial |> Status.lenses.jwt.set (jwt |> String.isEmpty |> not))
      }
    , cmd
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
        |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.jwt).set True
    , Cmd.none
    )
