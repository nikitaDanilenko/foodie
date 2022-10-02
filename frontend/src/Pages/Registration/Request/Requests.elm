module Pages.Registration.Request.Requests exposing (navigateToConfirmation, navigateToMain, request)

import Api.Types.UserIdentifier exposing (UserIdentifier, encoderUserIdentifier)
import Configuration exposing (Configuration)
import Http
import Pages.Registration.Request.Page as Page
import Pages.Util.Links as Links
import Url.Builder
import Util.HttpUtil as HttpUtil


request : Configuration -> UserIdentifier -> Cmd Page.Msg
request configuration userIdentifier =
    Http.post
        { url = Url.Builder.relative [ configuration.backendURL, "user", "registration", "request" ] []
        , expect = HttpUtil.expectWhatever Page.GotResponse
        , body = Http.jsonBody (encoderUserIdentifier userIdentifier)
        }



-- todo: Redirect to main page


navigateToMain : Configuration -> Cmd Page.Msg
navigateToMain =
    Links.navigateTo [ "login" ]


navigateToConfirmation : Configuration -> Cmd Page.Msg
navigateToConfirmation =
    Links.navigateTo [ "confirmation" ]
