module Pages.Registration.Request.Requests exposing (request)

import Addresses.Backend
import Api.Types.UserIdentifier exposing (UserIdentifier, encoderUserIdentifier)
import Configuration exposing (Configuration)
import Http
import Pages.Registration.Request.Page as Page
import Util.HttpUtil as HttpUtil


request : Configuration -> UserIdentifier -> Cmd Page.Msg
request configuration userIdentifier =
    HttpUtil.runPattern
        configuration
        Addresses.Backend.users.registration.request
        { jwt = Nothing
        , expect = HttpUtil.expectWhatever Page.GotRequestResponse
        , body = encoderUserIdentifier userIdentifier |> Http.jsonBody
        }
