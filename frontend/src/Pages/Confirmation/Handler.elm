module Pages.Confirmation.Handler exposing (init, update)

import Pages.Confirmation.Page as Page


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { configuration = flags.configuration }
    , Cmd.none
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update _ model = (model, Cmd.none)
