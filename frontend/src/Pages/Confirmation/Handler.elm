module Pages.Confirmation.Handler exposing (init, update)

import Pages.Confirmation.Page as Page
import Pages.Confirmation.Requests as Requests


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { configuration = flags.configuration }
    , Cmd.none
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.NavigateToMain ->
            navigateToMain model


navigateToMain : Page.Model -> ( Page.Model, Cmd Page.Msg )
navigateToMain model =
    ( model
    , Requests.navigateToMain model.configuration
    )
