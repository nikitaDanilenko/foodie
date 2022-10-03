module Pages.Registration.Confirm.Requests exposing (..)

import Api.Types.CreationComplement exposing (CreationComplement, encoderCreationComplement)
import Configuration exposing (Configuration)
import Http
import Pages.Registration.Confirm.Page as Page
import Pages.Util.Links as Links
import Url.Builder
import Util.HttpUtil as HttpUtil


request : Configuration -> CreationComplement -> Cmd Page.Msg
request configuration complement =
    Http.post
        { url = Url.Builder.relative [ configuration.backendURL, "user", "registration", "confirm" ] []
        , expect = HttpUtil.expectWhatever Page.GotResponse
        , body = Http.jsonBody (encoderCreationComplement complement)
        }


navigateToSuccess : Configuration -> Cmd Page.Msg
navigateToSuccess =
    Links.navigateTo [ "registration-successful" ]



--todo: Redirect to main


navigateToMain : Configuration -> Cmd Page.Msg
navigateToMain =
    Links.navigateTo [ "login" ]
