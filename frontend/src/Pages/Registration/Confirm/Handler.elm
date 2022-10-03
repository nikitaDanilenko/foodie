module Pages.Registration.Confirm.Handler exposing (init, update)

import Basics.Extra exposing (flip)
import Either
import Http exposing (Error)
import Pages.Registration.Confirm.Page as Page
import Pages.Registration.Confirm.Requests as Requests
import Util.HttpUtil as HttpUtil
import Util.Initialization exposing (Initialization(..))


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { userIdentifier = flags.userIdentifier
      , displayName = Nothing
      , password1 = ""
      , password2 = ""
      , configuration = flags.configuration
      , initialization = Loading ()
      , registrationJWT = flags.registrationJWT
      }
    , Cmd.none
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.SetDisplayName displayName ->
            setDisplayName model displayName

        Page.SetPassword1 password1 ->
            setPassword1 model password1

        Page.SetPassword2 password2 ->
            setPassword2 model password2

        Page.Request ->
            request model

        Page.GotResponse result ->
            gotResponse model result

        Page.NavigateToMain ->
            navigateToMain model


setDisplayName : Page.Model -> Maybe String -> ( Page.Model, Cmd Page.Msg )
setDisplayName model displayName =
    ( model |> Page.lenses.displayName.set displayName
    , Cmd.none
    )


setPassword1 : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setPassword1 model password1 =
    ( model |> Page.lenses.password1.set password1
    , Cmd.none
    )


setPassword2 : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setPassword2 model password2 =
    ( model |> Page.lenses.password2.set password2
    , Cmd.none
    )


request : Page.Model -> ( Page.Model, Cmd Page.Msg )
request model =
    ( model
    , Requests.request model.configuration
        { password = model.password1
        , displayName = model.displayName
        }
    )


gotResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotResponse model result =
    result
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
            (always
                ( model
                , Requests.navigateToSuccess model.configuration
                )
            )


navigateToMain : Page.Model -> ( Page.Model, Cmd Page.Msg )
navigateToMain model =
    ( model
    , Requests.navigateToMain model.configuration
    )
