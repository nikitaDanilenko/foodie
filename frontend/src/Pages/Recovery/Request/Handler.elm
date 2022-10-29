module Pages.Recovery.Request.Handler exposing (init, update)

import Api.Auxiliary exposing (UserId)
import Api.Types.User exposing (User)
import Basics.Extra exposing (flip)
import Either
import Pages.Recovery.Request.Page as Page
import Pages.Recovery.Request.Requests as Requests
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization as Initialization


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { configuration = flags.configuration
      , users = []
      , searchString = ""
      , initialization = Initialization.Loading ()
      , mode = Page.Initial
      }
    , Cmd.none
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.Find ->
            find model

        Page.GotFindResponse result ->
            gotFindResponse model result

        Page.SetSearchString string ->
            setSearchString model string

        Page.RequestRecovery userId ->
            requestRecovery model userId

        Page.GotRequestRecoveryResponse result ->
            gotRequestRecoveryResponse model result


find : Page.Model -> ( Page.Model, Cmd Page.Msg )
find model =
    ( model
    , Requests.find model.configuration model.searchString
    )


gotFindResponse : Page.Model -> Result Error (List User) -> ( Page.Model, Cmd Page.Msg )
gotFindResponse model result =
    result
        |> Either.fromResult
        |> Either.unpack (\error -> ( setError error model, Cmd.none ))
            (\users ->
                case users of
                    user :: [] ->
                        requestRecovery model user.id

                    _ ->
                        ( model
                            |> Page.lenses.users.set users
                            |> Page.lenses.mode.set Page.Requesting
                        , Cmd.none
                        )
            )


setSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setSearchString model string =
    ( model
        |> Page.lenses.searchString.set string
        |> Page.lenses.mode.set Page.Initial
    , Cmd.none
    )


requestRecovery : Page.Model -> UserId -> ( Page.Model, Cmd Page.Msg )
requestRecovery model userId =
    ( model
    , Requests.requestRecovery model.configuration userId
    )


gotRequestRecoveryResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotRequestRecoveryResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\_ -> model |> Page.lenses.mode.set Page.Requested)
    , Cmd.none
    )


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
