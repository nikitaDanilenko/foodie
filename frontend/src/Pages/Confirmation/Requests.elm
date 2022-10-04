module Pages.Confirmation.Requests exposing (..)

import Configuration exposing (Configuration)
import Pages.Confirmation.Page as Page
import Pages.Util.Links as Links



--todo redirect correctly to main page.


navigateToMain : Configuration -> Cmd Page.Msg
navigateToMain  =
    Links.navigateTo [ "login" ]
