module Pages.UserSettings.Requests exposing (..)

import Api.Types.PasswordChangeRequest exposing (PasswordChangeRequest, encoderPasswordChangeRequest)
import Api.Types.User exposing (decoderUser)
import Api.Types.UserUpdate exposing (UserUpdate, encoderUserUpdate)
import Json.Encode
import Pages.UserSettings.Page as Page
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Url.Builder
import Util.HttpUtil as HttpUtil


fetchUser : FlagsWithJWT -> Cmd Page.Msg
fetchUser flags =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "user" ] []
        , expect = HttpUtil.expectJson Page.GotFetchUserResponse decoderUser
        }


updatePassword : FlagsWithJWT -> PasswordChangeRequest -> Cmd Page.Msg
updatePassword flags passwordChangeRequest =
    HttpUtil.postJsonWithJWT
        flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "user", "update", "password" ] []
        , body = encoderPasswordChangeRequest passwordChangeRequest
        , expect = HttpUtil.expectWhatever Page.GotUpdatePasswordResponse
        }


updateSettings : FlagsWithJWT -> UserUpdate -> Cmd Page.Msg
updateSettings flags userUpdate =
    HttpUtil.postJsonWithJWT
        flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "user", "update" ] []
        , body = encoderUserUpdate userUpdate
        , expect = HttpUtil.expectJson Page.GotUpdateSettingsResponse decoderUser
        }


requestDeletion : FlagsWithJWT -> Cmd Page.Msg
requestDeletion flags =
    HttpUtil.postJsonWithJWT
        flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "user", "deletion", "request" ] []
        , body = Json.Encode.object []
        , expect = HttpUtil.expectWhatever Page.GotRequestDeletionResponse
        }
