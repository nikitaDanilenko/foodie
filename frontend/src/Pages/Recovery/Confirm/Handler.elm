module Pages.Recovery.Confirm.Handler exposing (init, update)

import Basics.Extra exposing (flip)
import Either
import Pages.Recovery.Confirm.Page as Page
import Pages.Recovery.Confirm.Requests as Requests
import Pages.Util.PasswordInput as PasswordInput exposing (PasswordInput)
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization as Initialization


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { configuration = flags.configuration
      , recoveryJwt = flags.recoveryJwt
      , userIdentifier = flags.userIdentifier
      , passwordInput = PasswordInput.initial
      , initialization = Initialization.Loading ()
      , mode = Page.Resetting
      }
    , Cmd.none
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.SetPasswordInput passwordInput ->
            setPasswordInput model passwordInput

        Page.Confirm ->
            confirm model

        Page.GotConfirmResponse result ->
            gotConfirmResponse model result


setPasswordInput : Page.Model -> PasswordInput -> ( Page.Model, Cmd Page.Msg )
setPasswordInput model passwordInput =
    ( model |> Page.lenses.passwordInput.set passwordInput
    , Cmd.none
    )


confirm : Page.Model -> ( Page.Model, Cmd Page.Msg )
confirm model =
    ( model
    , Requests.confirm
        { configuration = model.configuration
        , recoveryJwt = model.recoveryJwt
        , password = model.passwordInput.password1
        }
    )


gotConfirmResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotConfirmResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\_ ->
                model
                    |> Page.lenses.mode.set Page.Confirmed
                    |> Page.lenses.passwordInput.set PasswordInput.initial
            )
    , Cmd.none
    )


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
