module Pages.Registration.Request.Handler exposing (init, update)

import Basics.Extra exposing (flip)
import Browser.Navigation
import Either
import Http exposing (Error)
import Pages.Registration.Request.Page as Page
import Pages.Registration.Request.Requests as Requests
import Pages.Util.Links as Links
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)
import Util.HttpUtil as HttpUtil
import Util.Initialization exposing (Initialization(..))


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { nickname = ValidatedInput.nonEmptyString
      , email = ValidatedInput.nonEmptyString
      , configuration = flags.configuration
      , initialization = Loading ()
      }
    , Cmd.none
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.SetNickname nickname ->
            setNickname model nickname

        Page.SetEmail email ->
            setEmail model email

        Page.Request ->
            request model

        Page.GotResponse result ->
            gotResponse model result

        Page.Back ->
            back model


setNickname : Page.Model -> ValidatedInput String -> ( Page.Model, Cmd Page.Msg )
setNickname model nickname =
    ( model |> Page.lenses.nickname.set nickname
    , Cmd.none
    )


setEmail : Page.Model -> ValidatedInput String -> ( Page.Model, Cmd Page.Msg )
setEmail model email =
    ( model |> Page.lenses.email.set email
    , Cmd.none
    )


request : Page.Model -> ( Page.Model, Cmd Page.Msg )
request model =
    ( model
    , Requests.request
        model.configuration
        { nickname = model.nickname.value
        , email = model.email.value
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
                , Links.frontendPage [ "confirmation" ] model.configuration |> Browser.Navigation.load
                )
            )


back : Page.Model -> ( Page.Model, Cmd Page.Msg )
back model =
    ( model
    , Links.frontendPage [ "login" ] model.configuration |> Browser.Navigation.load
      --todo: Use main page
    )
