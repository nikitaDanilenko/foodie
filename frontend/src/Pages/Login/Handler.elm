module Pages.Login.Handler exposing (init, update)

import Addresses.Frontend
import Browser.Navigation
import Monocle.Compose as Compose
import Pages.Login.Page as Page
import Pages.Login.Requests as Requests
import Pages.Util.Links as Links
import Pages.View.Tristate as Tristate
import Ports
import Result.Extra
import Util.CredentialsUtil as CredentialsUtil
import Util.HttpUtil exposing (Error)


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { credentials =
            { nickname = ""
            , password = ""
            }
      }
        |> Tristate.createMain flags.configuration
    , Cmd.none
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    case msg of
        Page.SetNickname nickname ->
            setNickname model nickname

        Page.SetPassword password ->
            setPassword model password

        Page.Login ->
            login model

        Page.GotResponse remoteData ->
            gotResponse model remoteData


setNickname : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
setNickname model nickname =
    ( model
        |> Tristate.mapMain
            ((Page.lenses.main.credentials
                |> Compose.lensWithLens CredentialsUtil.nickname
             ).set
                nickname
            )
    , Cmd.none
    )


setPassword : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
setPassword model password =
    ( model
        |> Tristate.mapMain
            ((Page.lenses.main.credentials
                |> Compose.lensWithLens CredentialsUtil.password
             ).set
                password
            )
    , Cmd.none
    )


login : Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
login model =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Requests.login model.configuration main.credentials
            )
    )


gotResponse : Page.Model -> Result Error String -> ( Page.Model, Cmd Page.LogicMsg )
gotResponse model remoteData =
    remoteData
        |> Result.Extra.unpack
            (\error ->
                ( Tristate.toError model error
                , Cmd.none
                )
            )
            (\token ->
                ( model
                , Cmd.batch
                    [ Ports.storeToken token
                    , Addresses.Frontend.overview.address () |> Links.frontendPage |> Browser.Navigation.load
                    ]
                )
            )
