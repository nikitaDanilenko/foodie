module Util.HttpUtil exposing (..)

import Api.Auxiliary exposing (JWT)
import Configuration exposing (Configuration)
import Http exposing (Body, Error(..), Expect, expectStringResponse)
import Json.Decode as Decode
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Pages.Util.Links as Links
import Url.Builder exposing (QueryParameter)
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


setError : Lens model (Initialization status) -> Error -> model -> model
setError initializationLens =
    errorToExplanation
        >> (initializationLens |> Compose.lensWithOptional Initialization.lenses.failure).set


setJsonError : Lens model (Initialization status) -> Decode.Error -> model -> model
setJsonError initializationLens =
    Decode.errorToString
        >> BadBody
        >> setError initializationLens


type Verb
    = GET
    | POST
    | PUT
    | PATCH
    | DELETE


verbToString : Verb -> String
verbToString verb =
    case verb of
        GET ->
            "GET"

        POST ->
            "POST"

        PUT ->
            "PUT"

        PATCH ->
            "PATCH"

        DELETE ->
            "DELETE"


type alias RequestParameters msg =
    { url : String
    , jwt : Maybe JWT
    , body : Body
    , expect : Expect msg
    }


byVerb :
    Verb
    -> RequestParameters msg
    -> Cmd msg
byVerb verb ps =
    Http.request
        { method = verb |> verbToString
        , headers = Maybe.map jwtHeader ps.jwt |> Maybe.Extra.toList
        , url = ps.url
        , body = ps.body
        , expect = ps.expect
        , timeout = Nothing
        , tracker = Nothing
        }


type alias Resource =
    { url : String
    , verb : Verb
    }


type alias ResourcePattern =
    { verb : Verb
    , address : List String
    , query : List QueryParameter
    }


run :
    Resource
    ->
        { jwt : Maybe JWT
        , body : Body
        , expect : Expect msg
        }
    -> Cmd msg
run resource ps =
    byVerb resource.verb
        { url = resource.url
        , jwt = ps.jwt
        , body = ps.body
        , expect = ps.expect
        }


runPattern :
    Configuration
    -> ResourcePattern
    ->
        { jwt : Maybe JWT
        , body : Body
        , expect : Expect msg
        }
    -> Cmd msg
runPattern configuration resourcePattern =
    run
        { url = Links.backendPage configuration resourcePattern.address resourcePattern.query
        , verb = resourcePattern.verb
        }


runPatternWithJwt :
    FlagsWithJWT
    -> ResourcePattern
    ->
        { body : Body
        , expect : Expect msg
        }
    -> Cmd msg
runPatternWithJwt flags pattern ps =
    runPattern flags.configuration
        pattern
        { jwt = Just flags.jwt
        , body = ps.body
        , expect = ps.expect
        }
