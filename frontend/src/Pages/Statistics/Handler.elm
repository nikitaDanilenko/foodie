module Pages.Statistics.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT)
import Api.Lenses.RequestIntervalLens as RequestIntervalLens
import Api.Types.Date exposing (Date)
import Api.Types.Stats exposing (Stats)
import Basics.Extra exposing (flip)
import Either
import Http exposing (Error)
import Maybe.Extra
import Monocle.Compose as Compose
import Pages.Statistics.Page as Page
import Pages.Statistics.Requests as Requests
import Ports


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    let
        ( jwt, cmd ) =
            flags.jwt
                |> Maybe.Extra.unwrap
                    ( "", Ports.doFetchToken () )
                    (\token ->
                        ( token
                        , Cmd.none
                        )
                    )
    in
    ( { flagsWithJWT =
            { configuration = flags.configuration
            , jwt = jwt
            }
      , requestInterval = RequestIntervalLens.default
      , stats = defaultStats
      }
    , cmd
    )


defaultStats : Stats
defaultStats =
    { meals = []
    , nutrients = []
    }


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.SetStartDate maybeDate ->
            setStartDate model maybeDate

        Page.SetEndDate maybeDate ->
            setEndDate model maybeDate

        Page.FetchStats ->
            fetchStats model

        Page.GotFetchStatsResponse result ->
            gotFetchStatsResponse model result

        Page.UpdateJWT jwt ->
            updateJWT model jwt


setStartDate : Page.Model -> Maybe Date -> ( Page.Model, Cmd Page.Msg )
setStartDate model maybeDate =
    ( model
        |> (Page.lenses.requestInterval
                |> Compose.lensWithLens RequestIntervalLens.from
           ).set
            maybeDate
    , Cmd.none
    )


setEndDate : Page.Model -> Maybe Date -> ( Page.Model, Cmd Page.Msg )
setEndDate model maybeDate =
    ( model
        |> (Page.lenses.requestInterval
                |> Compose.lensWithLens RequestIntervalLens.to
           ).set
            maybeDate
    , Cmd.none
    )


updateJWT : Page.Model -> JWT -> ( Page.Model, Cmd Page.Msg )
updateJWT model jwt =
    ( model |> Page.lenses.jwt.set jwt
    , Cmd.none
    )


fetchStats : Page.Model -> ( Page.Model, Cmd Page.Msg )
fetchStats model =
    ( model
    , Requests.fetchStats model.flagsWithJWT model.requestInterval
    )


gotFetchStatsResponse : Page.Model -> Result Error Stats -> ( Page.Model, Cmd Page.Msg )
gotFetchStatsResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unwrap model (flip Page.lenses.stats.set model)
    , Cmd.none
    )
