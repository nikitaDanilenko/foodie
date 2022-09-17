module Pages.Statistics.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT)
import Api.Lenses.RequestIntervalLens as RequestIntervalLens
import Api.Lenses.StatsLens as StatsLens
import Api.Types.Date exposing (Date)
import Api.Types.Stats exposing (Stats)
import Basics.Extra exposing (flip)
import Either
import Http exposing (Error)
import Maybe.Extra
import Monocle.Lens as Lens
import Pages.Statistics.Page as Page
import Pages.Statistics.Requests as Requests
import Pages.Statistics.Status as Status
import Ports
import Util.HttpUtil as HttpUtil
import Util.Initialization as Initialization
import Util.LensUtil as LensUtil


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
      , initialization = Initialization.Loading (Status.initial |> Status.lenses.jwt.set (jwt |> String.isEmpty |> not))
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
        Page.SetFromDate maybeDate ->
            setFromDate model maybeDate

        Page.SetToDate maybeDate ->
            setToDate model maybeDate

        Page.FetchStats ->
            fetchStats model

        Page.GotFetchStatsResponse result ->
            gotFetchStatsResponse model result

        Page.UpdateJWT jwt ->
            updateJWT model jwt


setFromDate : Page.Model -> Maybe Date -> ( Page.Model, Cmd Page.Msg )
setFromDate model maybeDate =
    ( model
        |> Page.lenses.from.set
            maybeDate
    , Cmd.none
    )


setToDate : Page.Model -> Maybe Date -> ( Page.Model, Cmd Page.Msg )
setToDate model maybeDate =
    ( model
        |> Page.lenses.to.set
            maybeDate
    , Cmd.none
    )


updateJWT : Page.Model -> JWT -> ( Page.Model, Cmd Page.Msg )
updateJWT model jwt =
    ( model
        |> Page.lenses.jwt.set jwt
        |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.jwt).set True
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
        |> Either.unpack (flip setError model)
            (\stats ->
                model
                    |> Page.lenses.stats.set
                        (stats |> Lens.modify StatsLens.nutrients (List.sortBy .name))
            )
    , Cmd.none
    )


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
