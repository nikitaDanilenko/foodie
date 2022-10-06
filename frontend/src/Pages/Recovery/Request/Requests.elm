module Pages.Recovery.Request.Requests exposing (find, requestRecovery)

import Api.Auxiliary exposing (UserId)
import Api.Types.RecoveryRequest exposing (encoderRecoveryRequest)
import Api.Types.User exposing (decoderUser)
import Configuration exposing (Configuration)
import Http
import Json.Decode as Decode
import Pages.Recovery.Request.Page as Page
import Pages.Util.Links as Links


find : Configuration -> String -> Cmd Page.Msg
find configuration searchString =
    Http.get
        { url = Links.backendPage configuration [ "user", "recovery", "find", searchString ]
        , expect = Http.expectJson Page.GotFindResponse (Decode.list decoderUser)
        }


requestRecovery : Configuration -> UserId -> Cmd Page.Msg
requestRecovery configuration userId =
    Http.post
        { url = Links.backendPage configuration [ "user", "recovery", "request" ]
        , body = encoderRecoveryRequest { userId = userId } |> Http.jsonBody
        , expect = Http.expectJson Page.GotFindResponse (Decode.list decoderUser)
        }
