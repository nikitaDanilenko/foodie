module Pages.Deletion.Confirmation.Handler exposing (init, update)

import Either
import Http exposing (Error)
import Pages.Deletion.Confirmation.Page as Page
import Pages.Deletion.Confirmation.Requests as Requests
import Pages.Util.Links as Links
import Util.HttpUtil as HttpUtil
import Util.Initialization exposing (Initialization(..))


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { deletionJWT = flags.deletionJWT
      , userIdentifier = flags.userIdentifier
      , configuration = flags.configuration
      , initialization = Loading ()
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

        Page.NavigateToMain ->
            navigateToMain model


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
            (\_ -> ( model, Links.navigateTo [ "deleted" ] model.configuration ))


navigateToMain : Page.Model -> ( Page.Model, Cmd Page.Msg )
navigateToMain model =
    ( model
    , Requests.navigateToMain model.configuration
    )


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
