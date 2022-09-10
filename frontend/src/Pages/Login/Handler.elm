module Pages.Login.Handler exposing (init, update)

import Either
import Monocle.Compose as Compose
import Pages.Login.Page as Page
import Pages.Login.Requests as Requests
import Ports
import Util.CredentialsUtil as CredentialsUtil
import Util.TriState exposing (TriState(..))


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
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


gotResponse model remoteData =
    remoteData
        |> Either.fromResult
        |> Either.unwrap ( Page.lenses.state.set Failure model, Cmd.none )
            (\token ->
                ( Page.lenses.state.set Success model
                , Cmd.batch
                    [ Ports.storeToken token
                    , Requests.navigateToOverview model.configuration
                    ]
                )
            )
