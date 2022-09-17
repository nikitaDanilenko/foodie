module Util.HttpUtil exposing (..)

import Api.Auxiliary exposing (JWT)
import Http exposing (Error(..), Expect, expectStringResponse)
import Json.Decode as Decode
import Json.Encode as Encode
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Util.Initialization as Initialization exposing (ErrorExplanation, Initialization)


expectJson : (Result Http.Error a -> msg) -> Decode.Decoder a -> Expect msg
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

                Http.BadStatus_ metadata _ ->
                    Err (BadStatus metadata.statusCode)

                Http.GoodStatus_ _ body ->
                    case Decode.decodeString decoder body of
                        Ok value ->
                            Ok value

                        Err err ->
                            Err (BadBody (Decode.errorToString err))


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


errorToExplanation : Error -> ErrorExplanation
errorToExplanation error =
    case error of
        BadUrl string ->
            { cause = "BadUrl: " ++ string
            , possibleSolution = "Check address. If the error persists, please contact an administrator."
            , redirectToLogin = False
            }

        Timeout ->
            { cause = "Timeout"
            , possibleSolution = "Try again later. If the error persists, please contact an administrator."
            , redirectToLogin = False
            }

        NetworkError ->
            { cause = "Timeout"
            , possibleSolution = "Try again later. If the error persists, please contact an administrator."
            , redirectToLogin = False
            }

        BadStatus code ->
            { cause = "BadStatus: " ++ String.fromInt code
            , possibleSolution =
                if code == 401 then
                    "Please log in again to continue."

                else
                    ""
            , redirectToLogin = code == 401
            }

        BadBody string ->
            { cause = "Bad body: " ++ string
            , possibleSolution = ""
            , redirectToLogin = False
            }


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


setError : Lens model (Initialization status) -> Error -> model -> model
setError initializationLens =
    errorToExplanation
        >> (initializationLens |> Compose.lensWithOptional Initialization.lenses.failure).set


setJsonError : Lens model (Initialization status) -> Decode.Error -> model -> model
setJsonError initializationLens =
    Decode.errorToString
        >> BadBody
        >> setError initializationLens
