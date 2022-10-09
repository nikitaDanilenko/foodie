module Pages.Recovery.Confirm.Requests exposing (confirm)

import Api.Auxiliary exposing (JWT)
import Api.Types.PasswordChangeRequest exposing (encoderPasswordChangeRequest)
import Configuration exposing (Configuration)
import Pages.Recovery.Confirm.Page as Page
import Pages.Util.Links as Links
import Util.HttpUtil as HttpUtil


confirm :
    { configuration : Configuration
    , recoveryJwt : JWT
    , password : String
    }
    -> Cmd Page.Msg
confirm params =
    HttpUtil.postJsonWithJWT
        params.recoveryJwt
        { url = Links.backendPage params.configuration [ "user", "recovery", "confirm" ] []
        , body = encoderPasswordChangeRequest { password = params.password }
        , expect = HttpUtil.expectWhatever Page.GotConfirmResponse
        }
