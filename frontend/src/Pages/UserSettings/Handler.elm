module Pages.UserSettings.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT, UserId)
import Api.Types.Mode exposing (Mode)
import Api.Types.User exposing (User)
import Basics.Extra exposing (flip)
import Browser.Navigation
import Either
import Http exposing (Error)
import Maybe.Extra
import Monocle.Lens as Lens
import Pages.UserSettings.Page as Page
import Pages.UserSettings.Requests as Requests
import Pages.UserSettings.Status as Status
import Pages.Util.ComplementInput as ComplementInput exposing (ComplementInput)
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Pages.Util.Links as Links
import Ports
import Util.HttpUtil as HttpUtil
import Util.Initialization exposing (Initialization(..))
import Util.LensUtil as LensUtil


initialFetch : FlagsWithJWT -> Cmd Page.Msg
initialFetch =
    Requests.fetchUser


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    let
        ( jwt, cmd ) =
            flags.jwt
                |> Maybe.Extra.unwrap
                    ( "", Ports.doFetchToken () )
                    (\token ->
                        ( token
                        , Requests.fetchUser
                            { configuration = flags.configuration
                            , jwt = token
                            }
                        )
                    )
    in
    ( { flagsWithJWT =
            { configuration = flags.configuration
            , jwt = jwt
            }
      , user =
            { id = ""
            , nickname = ""
            , displayName = Nothing
            , email = ""
            }
      , complementInput = ComplementInput.initial
      , initialization = Loading Status.initial
      }
    , cmd
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.UpdateJWT jwt ->
            updateJWT model jwt

        Page.GotFetchUserResponse result ->
            gotFetchUserResponse model result

        Page.UpdatePassword ->
            updatePassword model

        Page.GotUpdatePasswordResponse result ->
            gotUpdatePasswordResponse model result

        Page.UpdateSettings ->
            updateSettings model

        Page.GotUpdateSettingsResponse result ->
            gotUpdateSettingsResponse model result

        Page.RequestDeletion ->
            requestDeletion model

        Page.GotRequestDeletionResponse result ->
            gotRequestDeletionResponse model result

        Page.SetComplementInput complementInput ->
            setComplementInput model complementInput

        Page.Logout logoutKind ->
            logout model logoutKind

        Page.GotLogoutResponse result ->
            gotLogoutResponse model result


updateJWT : Page.Model -> JWT -> ( Page.Model, Cmd Page.Msg )
updateJWT model token =
    let
        newModel =
            model
                |> Page.lenses.jwt.set token
                |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.jwt).set True
    in
    ( newModel
    , initialFetch newModel.flagsWithJWT
    )


gotFetchUserResponse : Page.Model -> Result Error User -> ( Page.Model, Cmd Page.Msg )
gotFetchUserResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (flip Page.lenses.user.set model)
    , Cmd.none
    )


updatePassword : Page.Model -> ( Page.Model, Cmd Page.Msg )
updatePassword model =
    ( model
    , Requests.updatePassword
        model.flagsWithJWT
        { password = model.complementInput.password1 }
    )


gotUpdatePasswordResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotUpdatePasswordResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\_ ->
                Lens.modify Page.lenses.complementInput
                    (ComplementInput.lenses.password1.set "" >> ComplementInput.lenses.password2.set "")
                    model
            )
    , Cmd.none
    )


updateSettings : Page.Model -> ( Page.Model, Cmd Page.Msg )
updateSettings model =
    ( model
    , Requests.updateSettings
        model.flagsWithJWT
        { displayName = model.complementInput.displayName }
    )


gotUpdateSettingsResponse : Page.Model -> Result Error User -> ( Page.Model, Cmd Page.Msg )
gotUpdateSettingsResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (flip Page.lenses.user.set model)
    , Cmd.none
    )


requestDeletion : Page.Model -> ( Page.Model, Cmd Page.Msg )
requestDeletion model =
    ( model
    , Requests.requestDeletion model.flagsWithJWT
    )


gotRequestDeletionResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotRequestDeletionResponse model result =
    result
        |> Either.fromResult
        |> Either.unpack (\error -> ( model |> setError error, Cmd.none ))
            (\_ -> ( model, Links.frontendPage [ "confirmation" ] model.flagsWithJWT.configuration |> Browser.Navigation.load ))


setComplementInput : Page.Model -> ComplementInput -> ( Page.Model, Cmd Page.Msg )
setComplementInput model complementInput =
    ( model |> Page.lenses.complementInput.set complementInput
    , Cmd.none
    )


logout : Page.Model -> Mode -> ( Page.Model, Cmd Page.Msg )
logout model mode =
    ( model
    , Requests.logout model.flagsWithJWT mode
    )



--todo: Redirect to main page


gotLogoutResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotLogoutResponse model result =
    result
        |> Either.fromResult
        |> Either.unpack (\error -> ( model |> setError error, Cmd.none ))
            (\_ -> ( model, Links.frontendPage [ "login" ] model.flagsWithJWT.configuration |> Browser.Navigation.load ))


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization