module Pages.Registration.Request.Handler exposing (init, update)

import Basics.Extra exposing (flip)
import Either
import Pages.Registration.Request.Page as Page
import Pages.Registration.Request.Requests as Requests
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization(..))


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { nickname = ValidatedInput.nonEmptyString
      , email = ValidatedInput.nonEmptyString
      , configuration = flags.configuration
      , initialization = Loading ()
      , mode = Page.Editing
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

        Page.GotRequestResponse result ->
            gotRequestResponse model result


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


gotRequestResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotRequestResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack
            (flip setError model)
            (\_ -> model |> Page.lenses.mode.set Page.Confirmed)
    , Cmd.none
    )


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
