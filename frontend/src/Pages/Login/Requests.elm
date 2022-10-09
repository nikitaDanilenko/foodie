module Pages.Login.Requests exposing (login)

import Addresses.Backend
import Api.Types.Credentials exposing (Credentials, encoderCredentials)
import Configuration exposing (Configuration)
import Http exposing (Error)
import Json.Decode as Decode
import Pages.Login.Page as Page
import Util.HttpUtil as HttpUtil


login : Configuration -> Credentials -> Cmd Page.Msg
login configuration credentials =
    HttpUtil.runPattern
        configuration
        Addresses.Backend.users.login
        { jwt = Nothing
        , body = Http.jsonBody <| encoderCredentials credentials
        , expect = HttpUtil.expectJson Page.GotResponse Decode.string
        }
