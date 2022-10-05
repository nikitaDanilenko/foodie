module Pages.Deletion.Handler exposing (init, update)

import Either
import Http exposing (Error)
import Pages.Deletion.Page as Page
import Pages.Deletion.Requests as Requests
import Ports
import Util.HttpUtil as HttpUtil
import Util.Initialization exposing (Initialization(..))


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { deletionJWT = flags.deletionJWT
      , userIdentifier = flags.userIdentifier
      , configuration = flags.configuration
      , initialization = Loading ()
      , mode = Page.Checking
      }
    , Cmd.none
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.Confirm ->
            confirm model

        Page.GotConfirmResponse result ->
            gotConfirmResponse model result


confirm : Page.Model -> ( Page.Model, Cmd Page.Msg )
confirm model =
    ( model
    , Requests.deleteUser model.configuration model.deletionJWT
    )


gotConfirmResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotConfirmResponse model result =
    result
        |> Either.fromResult
        |> Either.unpack (\error -> ( model |> setError error, Cmd.none ))
            (\_ -> ( model |> Page.lenses.mode.set Page.Confirmed, Ports.doDeleteToken () ))


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
