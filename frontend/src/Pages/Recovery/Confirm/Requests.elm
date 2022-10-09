module Pages.Recovery.Confirm.Requests exposing (confirm)

import Addresses.Backend
import Api.Auxiliary exposing (JWT)
import Api.Types.PasswordChangeRequest exposing (encoderPasswordChangeRequest)
import Configuration exposing (Configuration)
import Http
import Pages.Recovery.Confirm.Page as Page
import Util.HttpUtil as HttpUtil


confirm :
    { configuration : Configuration
    , recoveryJwt : JWT
    , password : String
    }
    -> Cmd Page.Msg
confirm params =
    HttpUtil.runPatternWithJwt
        { configuration = params.configuration
        , jwt = params.recoveryJwt
        }
        Addresses.Backend.users.recovery.confirm
        { body = encoderPasswordChangeRequest { password = params.password } |> Http.jsonBody
        , expect = HttpUtil.expectWhatever Page.GotConfirmResponse
        }
