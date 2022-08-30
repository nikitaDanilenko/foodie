module Util.HttpUtil exposing (..)

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
userTokenHeader = "User-Token"

postJsonWithJWT :
    String
    ->
        { url : String
        , body : Encode.Value
        , expect : Expect msg
        }
    -> Cmd msg
postJsonWithJWT jwt request =
    Http.request
        { method = "POST"
        , headers = [ Http.header userTokenHeader jwt ]
        , url = request.url
        , body = Http.jsonBody request.body
        , expect = request.expect
        , timeout = Nothing
        , tracker = Nothing
        }