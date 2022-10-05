module Pages.Deletion.Requests exposing (..)

import Api.Auxiliary exposing (JWT)
import Configuration exposing (Configuration)
import Json.Encode
import Pages.Deletion.Page as Page
import Url.Builder
import Util.HttpUtil as HttpUtil


deleteUser : Configuration -> JWT -> Cmd Page.Msg
deleteUser configuration jwt =
    HttpUtil.postJsonWithJWT
        jwt
        { url = Url.Builder.relative [ configuration.backendURL, "user", "deletion", "confirm" ] []
        , body = Json.Encode.object []
        , expect = HttpUtil.expectWhatever Page.GotConfirmResponse
        }
