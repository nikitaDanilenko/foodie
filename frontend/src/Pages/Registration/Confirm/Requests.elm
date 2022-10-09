module Pages.Registration.Confirm.Requests exposing (..)

import Addresses.Backend
import Api.Auxiliary exposing (JWT)
import Api.Types.CreationComplement exposing (CreationComplement, encoderCreationComplement)
import Configuration exposing (Configuration)
import Http
import Pages.Registration.Confirm.Page as Page
import Util.HttpUtil as HttpUtil


request : Configuration -> JWT -> CreationComplement -> Cmd Page.Msg
request configuration jwt complement =
    HttpUtil.runPatternWithJwt
        { configuration = configuration
        , jwt = jwt
        }
        Addresses.Backend.users.registration.confirm
        { expect = HttpUtil.expectWhatever Page.GotResponse
        , body = encoderCreationComplement complement |> Http.jsonBody
        }
