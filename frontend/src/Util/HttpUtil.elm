module Util.HttpUtil exposing (..)

import Api.Auxiliary exposing (JWT)
import Configuration exposing (Configuration)
import Http exposing (Body, Error(..), Expect, expectStringResponse)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Links as Links
import Url.Builder exposing (QueryParameter)
import Util.Initialization as Initialization exposing (ErrorExplanation, Initialization)


type Error
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Int String
    | BadBody String


type alias BackendError =
    { message : String
    }


decoderBackendError : Decode.Decoder BackendError
decoderBackendError =
    Decode.succeed BackendError
        |> required "message" Decode.string


expectJson : (Result Error a -> msg) -> Decode.Decoder a -> Expect msg
expectJson toMsg decoder =
    expectStringResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (BadUrl url)

                Http.Timeout_ ->
                    Err Timeout

                Http.NetworkError_ ->
                    Err NetworkError

                Http.BadStatus_ metadata body ->
                    Decode.decodeString decoderBackendError body
                        |> Result.mapError (Decode.errorToString >> BadBody)
                        |> Result.andThen (.message >> BadStatus metadata.statusCode >> Err)

                Http.GoodStatus_ _ body ->
                    Decode.decodeString decoder body
                        |> Result.mapError (Decode.errorToString >> BadBody)


expectWhatever : (Result Error () -> msg) -> Expect msg
expectWhatever toMsg =
    expectStringResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (BadUrl url)

                Http.Timeout_ ->
                    Err Timeout

                Http.NetworkError_ ->
                    Err NetworkError

                Http.BadStatus_ _ body ->
                    Err (BadBody body)

                Http.GoodStatus_ _ _ ->
                    Ok ()


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

        BadStatus code explanation ->
            { cause = "BadStatus: " ++ String.fromInt code ++ " - " ++ explanation
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
    AuthorizedAccess
    -> ResourcePattern
    ->
        { body : Body
        , expect : Expect msg
        }
    -> Cmd msg
runPatternWithJwt authorizedAccess pattern ps =
    runPattern authorizedAccess.configuration
        pattern
        { jwt = Just authorizedAccess.jwt
        , body = ps.body
        , expect = ps.expect
        }
