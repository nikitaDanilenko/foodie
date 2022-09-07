module Pages.Login exposing (Flags, Model, Msg, init, update, view)

import Api.Types.Credentials exposing (Credentials, encoderCredentials)
import Browser.Navigation
import Configuration exposing (Configuration)
import Html exposing (Html, button, div, input, label, text)
import Html.Attributes exposing (autocomplete, class, for, id, type_)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Http exposing (Error)
import Json.Decode as Decode
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Ports exposing (storeToken)
import Url.Builder
import Util.CredentialsUtil as CredentialsUtil
import Util.HttpUtil as HttpUtil
import Util.TriState exposing (TriState(..))


type alias Model =
    { credentials : Credentials
    , state : TriState
    , configuration : Configuration
    }


credentials : Lens Model Credentials
credentials =
    Lens .credentials (\b a -> { a | credentials = b })


state : Lens Model TriState
state =
    Lens .state (\b a -> { a | state = b })


type Msg
    = SetNickname String
    | SetPassword String
    | Login
    | GotResponse (Result Error String)


type alias Flags =
    { configuration : Configuration
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { credentials =
            { nickname = ""
            , password = ""
            }
      , state = Initial
      , configuration = flags.configuration
      }
    , Cmd.none
    )


view : Model -> Html Msg
view _ =
    div [ id "initialMain" ]
        [ div [ id "userField" ]
            [ label [ for "user" ] [ text "Nickname" ]
            , input [ autocomplete True, onInput SetNickname, onEnter Login ] []
            ]
        , div [ id "passwordField" ]
            [ label [ for "password" ] [ text "Password" ]
            , input [ type_ "password", autocomplete True, onInput SetPassword, onEnter Login ] []
            ]
        , div [ id "fetchButton" ]
            [ button [ class "button", onClick Login ] [ text "Log In" ] ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetNickname n ->
            ( (credentials
                |> Compose.lensWithLens CredentialsUtil.nickname
              ).set
                n
                model
            , Cmd.none
            )

        SetPassword p ->
            ( (credentials
                |> Compose.lensWithLens CredentialsUtil.password
              ).set
                p
                model
            , Cmd.none
            )

        Login ->
            ( model, login model.configuration model.credentials )

        GotResponse remoteData ->
            case remoteData of
                Ok token ->
                    ( state.set Success model
                    , Cmd.batch
                        [ storeToken token
                        , navigateToOverview model.configuration
                        ]
                    )

                Err _ ->
                    ( state.set Failure model, Cmd.none )


login : Configuration -> Credentials -> Cmd Msg
login conf cred =
    Http.post
        { url = Url.Builder.relative [ conf.backendURL, "login" ] []
        , expect = HttpUtil.expectJson GotResponse Decode.string
        , body = Http.jsonBody (encoderCredentials cred)
        }


navigateToOverview : Configuration -> Cmd Msg
navigateToOverview conf =
    let
        address =
            Url.Builder.relative [ conf.mainPageURL, "#", "overview" ] []
    in
    Browser.Navigation.load address
