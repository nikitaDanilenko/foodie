module Pages.Registration.Confirm.Requests exposing (..)

import Api.Auxiliary exposing (JWT)
import Api.Types.CreationComplement exposing (CreationComplement, encoderCreationComplement)
import Configuration exposing (Configuration)
import Pages.Registration.Confirm.Page as Page
import Url.Builder
import Util.HttpUtil as HttpUtil


request : Configuration -> JWT -> CreationComplement -> Cmd Page.Msg
request configuration jwt complement =
    HttpUtil.postJsonWithJWT jwt
        { url = Url.Builder.relative [ configuration.backendURL, "user", "registration", "confirm" ] []
        , expect = HttpUtil.expectWhatever Page.GotResponse
        , body = encoderCreationComplement complement
        }
