module Pages.Registration.Request.Requests exposing (request)

import Api.Types.UserIdentifier exposing (UserIdentifier, encoderUserIdentifier)
import Configuration exposing (Configuration)
import Http
import Pages.Registration.Request.Page as Page
import Pages.Util.Links as Links
import Util.HttpUtil as HttpUtil


request : Configuration -> UserIdentifier -> Cmd Page.Msg
request configuration userIdentifier =
    Http.post
        { url = Links.backendPage configuration [ "user", "registration", "request" ] []
        , expect = HttpUtil.expectWhatever Page.GotRequestResponse
        , body = Http.jsonBody (encoderUserIdentifier userIdentifier)
        }
