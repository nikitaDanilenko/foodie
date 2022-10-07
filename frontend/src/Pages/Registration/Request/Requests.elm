module Pages.Registration.Request.Requests exposing (request)

import Api.Types.UserIdentifier exposing (UserIdentifier, encoderUserIdentifier)
import Configuration exposing (Configuration)
import Http
import Pages.Registration.Request.Page as Page
import Url.Builder
import Util.HttpUtil as HttpUtil


request : Configuration -> UserIdentifier -> Cmd Page.Msg
request configuration userIdentifier =
    Http.post
        { url = Url.Builder.relative [ configuration.backendURL, "user", "registration", "request" ] []
        , expect = HttpUtil.expectWhatever Page.GotRequestResponse
        , body = Http.jsonBody (encoderUserIdentifier userIdentifier)
        }
