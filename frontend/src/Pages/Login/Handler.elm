module Pages.Login.Handler exposing (init, update)

import Addresses.Frontend
import Basics.Extra exposing (flip)
import Browser.Navigation
import Either
import Http exposing (Error)
import Monocle.Compose as Compose
import Pages.Login.Page as Page
import Pages.Login.Requests as Requests
import Pages.Util.Links as Links
import Ports
import Util.CredentialsUtil as CredentialsUtil
import Util.HttpUtil as HttpUtil
import Util.Initialization exposing (Initialization(..))


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { credentials =
            { nickname = ""
            , password = ""
            }
      , initialization = Loading ()
      , configuration = flags.configuration
      }
    , Cmd.none
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.SetNickname nickname ->
            setNickname model nickname

        Page.SetPassword password ->
            setPassword model password

        Page.Login ->
            login model

        Page.GotResponse remoteData ->
            gotResponse model remoteData


setNickname : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setNickname model nickname =
    ( (Page.lenses.credentials
        |> Compose.lensWithLens CredentialsUtil.nickname
      ).set
        nickname
        model
    , Cmd.none
    )


setPassword : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setPassword model password =
    ( (Page.lenses.credentials
        |> Compose.lensWithLens CredentialsUtil.password
      ).set
        password
        model
    , Cmd.none
    )


login : Page.Model -> ( Page.Model, Cmd Page.Msg )
login model =
    ( model
    , Requests.login model.configuration model.credentials
    )


gotResponse : Page.Model -> Result Error String -> ( Page.Model, Cmd Page.Msg )
gotResponse model remoteData =
    remoteData
        |> Either.fromResult
        |> Either.unpack
            (\error ->
                ( error
                    |> HttpUtil.errorToExplanation
                    |> Failure
                    |> flip Page.lenses.initialization.set model
                , Cmd.none
                )
            )
            (\token ->
                ( model
                , Cmd.batch
                    [ Ports.storeToken token
                    , Addresses.Frontend.overview.address () |> Links.frontendPage model.configuration |> Browser.Navigation.load
                    ]
                )
            )
