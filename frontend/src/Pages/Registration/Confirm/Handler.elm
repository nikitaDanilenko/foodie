module Pages.Registration.Confirm.Handler exposing (init, update)

import Basics.Extra exposing (flip)
import Either
import Pages.Registration.Confirm.Page as Page
import Pages.Registration.Confirm.Requests as Requests
import Pages.Util.ComplementInput as ComplementInput exposing (ComplementInput)
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization(..))


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { userIdentifier = flags.userIdentifier
      , complementInput = ComplementInput.initial
      , configuration = flags.configuration
      , initialization = Loading ()
      , registrationJWT = flags.registrationJWT
      , mode = Page.Editing
      }
    , Cmd.none
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.SetComplementInput complementInput ->
            setComplementInput model complementInput

        Page.Request ->
            request model

        Page.GotResponse result ->
            gotResponse model result


setComplementInput : Page.Model -> ComplementInput -> ( Page.Model, Cmd Page.Msg )
setComplementInput model complementInput =
    ( model |> Page.lenses.complementInput.set complementInput
    , Cmd.none
    )


request : Page.Model -> ( Page.Model, Cmd Page.Msg )
request model =
    ( model
    , Requests.request model.configuration
        model.registrationJWT
        { password = model.complementInput.passwordInput.password1
        , displayName = model.complementInput.displayName
        }
    )


gotResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack
            (HttpUtil.errorToExplanation
                >> Failure
                >> flip Page.lenses.initialization.set model
            )
            (\_ -> model |> Page.lenses.mode.set Page.Confirmed)
    , Cmd.none
    )
