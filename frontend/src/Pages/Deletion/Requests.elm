module Pages.Deletion.Requests exposing (..)

import Addresses.Backend
import Api.Auxiliary exposing (JWT)
import Configuration exposing (Configuration)
import Http
import Pages.Deletion.Page as Page
import Util.HttpUtil as HttpUtil


deleteUser : Configuration -> JWT -> Cmd Page.Msg
deleteUser configuration jwt =
    HttpUtil.runPatternWithJwt
        { configuration = configuration
        , jwt = jwt
        }
        Addresses.Backend.users.deletion.confirm
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever Page.GotConfirmResponse
        }
