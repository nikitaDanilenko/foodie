module Pages.UserSettings.Requests exposing (..)

import Addresses.Backend
import Api.Types.LogoutRequest exposing (encoderLogoutRequest)
import Api.Types.Mode exposing (Mode)
import Api.Types.PasswordChangeRequest exposing (PasswordChangeRequest, encoderPasswordChangeRequest)
import Api.Types.User exposing (decoderUser)
import Api.Types.UserUpdate exposing (UserUpdate, encoderUserUpdate)
import Http
import Pages.UserSettings.Page as Page
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Util.HttpUtil as HttpUtil


fetchUser : FlagsWithJWT -> Cmd Page.Msg
fetchUser flags =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.users.get
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchUserResponse decoderUser
        }


updatePassword : FlagsWithJWT -> PasswordChangeRequest -> Cmd Page.Msg
updatePassword flags passwordChangeRequest =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.users.updatePassword
        { body = encoderPasswordChangeRequest passwordChangeRequest |> Http.jsonBody
        , expect = HttpUtil.expectWhatever Page.GotUpdatePasswordResponse
        }


updateSettings : FlagsWithJWT -> UserUpdate -> Cmd Page.Msg
updateSettings flags userUpdate =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.users.update
        { body = encoderUserUpdate userUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotUpdateSettingsResponse decoderUser
        }


requestDeletion : FlagsWithJWT -> Cmd Page.Msg
requestDeletion flags =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.users.deletion.request
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever Page.GotRequestDeletionResponse
        }


logout : FlagsWithJWT -> Mode -> Cmd Page.Msg
logout flags mode =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.users.logout
        { body = encoderLogoutRequest { mode = mode } |> Http.jsonBody
        , expect = HttpUtil.expectWhatever Page.GotLogoutResponse
        }
