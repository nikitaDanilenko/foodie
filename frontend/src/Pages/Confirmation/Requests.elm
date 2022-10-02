module Pages.Confirmation.Requests exposing (..)

import Browser.Navigation
import Configuration exposing (Configuration)
import Pages.Confirmation.Page as Page
import Url.Builder



--todo redirect correctly to main page.


navigateToMain : Configuration -> Cmd Page.Msg
navigateToMain configuration =
    let
        address =
            Url.Builder.relative [ configuration.mainPageURL, "#", "login" ] []
    in
    Browser.Navigation.load address
