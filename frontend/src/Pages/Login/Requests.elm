module Pages.Login.Requests exposing (login)

import Api.Types.Credentials exposing (Credentials, encoderCredentials)
import Configuration exposing (Configuration)
import Http exposing (Error)
import Json.Decode as Decode
import Pages.Login.Page as Page
import Pages.Util.Links as Links
import Util.HttpUtil as HttpUtil


login : Configuration -> Credentials -> Cmd Page.Msg
login configuration credentials =
    Http.post
        { url = Links.backendPage configuration [ "login" ] []
        , expect = HttpUtil.expectJson Page.GotResponse Decode.string
        , body = Http.jsonBody (encoderCredentials credentials)
        }
