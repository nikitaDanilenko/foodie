module Pages.Login.Requests exposing (login, navigateToOverview)

import Api.Types.Credentials exposing (Credentials, encoderCredentials)
import Browser.Navigation
import Configuration exposing (Configuration)
import Http exposing (Error)
import Json.Decode as Decode
import Pages.Login.Page as Page
import Url.Builder
import Util.HttpUtil as HttpUtil


login : Configuration -> Credentials -> Cmd Page.Msg
login configuration credentials =
    Http.post
        { url = Url.Builder.relative [ configuration.backendURL, "login" ] []
        , expect = HttpUtil.expectJson Page.GotResponse Decode.string
        , body = Http.jsonBody (encoderCredentials credentials)
        }


navigateToOverview : Configuration -> Cmd Page.Msg
navigateToOverview configuration =
    let
        address =
            Url.Builder.relative [ configuration.mainPageURL, "#", "overview" ] []
    in
    Browser.Navigation.load address
