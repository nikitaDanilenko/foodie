module Util.HttpUtil exposing (..)

import Api.Auxiliary exposing (JWT)
import Http exposing (Error(..), Expect, expectStringResponse)
import Json.Decode as D
import Json.Encode as Encode


expectJson : (Result Http.Error a -> msg) -> D.Decoder a -> Expect msg
expectJson toMsg decoder =
    expectStringResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (Http.BadUrl url)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ _ body ->
                    Err (BadBody body)

                Http.GoodStatus_ _ body ->
                    case D.decodeString decoder body of
                        Ok value ->
                            Ok value

                        Err err ->
                            Err (BadBody (D.errorToString err))


expectWhatever : (Result Http.Error () -> msg) -> Expect msg
expectWhatever toMsg =
    expectStringResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (Http.BadUrl url)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ _ body ->
                    Err (BadBody body)

                Http.GoodStatus_ _ _ ->
                    Ok ()


errorToString : Error -> String
errorToString error =
    case error of
        BadUrl string ->
            "BadUrl: " ++ string

        Timeout ->
            "Timeout"

        NetworkError ->
            "NetworkError"

        BadStatus int ->
            "BadStatus: " ++ String.fromInt int

        BadBody string ->
            string


userTokenHeader : String
userTokenHeader =
    "User-Token"


jwtHeader : JWT -> Http.Header
jwtHeader =
    Http.header userTokenHeader


postJsonWithJWT :
    JWT
    ->
        { url : String
        , body : Encode.Value
        , expect : Expect msg
        }
    -> Cmd msg
postJsonWithJWT =
    sendJsonWithJWTVerb "POST"


patchJsonWithJWT :
    JWT
    ->
        { url : String
        , body : Encode.Value
        , expect : Expect msg
        }
    -> Cmd msg
patchJsonWithJWT =
    sendJsonWithJWTVerb "PATCH"


sendJsonWithJWTVerb :
    String
    -> JWT
    ->
        { url : String
        , body : Encode.Value
        , expect : Expect msg
        }
    -> Cmd msg
sendJsonWithJWTVerb verb jwt request =
    Http.request
        { method = verb
        , headers = [ jwtHeader jwt ]
        , url = request.url
        , body = Http.jsonBody request.body
        , expect = request.expect
        , timeout = Nothing
        , tracker = Nothing
        }


deleteWithJWT :
    JWT
    ->
        { url : String
        , expect : Expect msg
        }
    -> Cmd msg
deleteWithJWT jwt request =
    Http.request
        { method = "DELETE"
        , headers = [ jwtHeader jwt ]
        , url = request.url
        , body = Http.emptyBody
        , expect = request.expect
        , timeout = Nothing
        , tracker = Nothing
        }


getJsonWithJWT :
    JWT
    ->
        { url : String
        , expect : Expect msg
        }
    -> Cmd msg
getJsonWithJWT jwt request =
    Http.request
        { method = "GET"
        , headers = [ jwtHeader jwt ]
        , url = request.url
        , body = Http.emptyBody
        , expect = request.expect
        , timeout = Nothing
        , tracker = Nothing
        }
