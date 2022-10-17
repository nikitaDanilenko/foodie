module Pages.Statistics.Handler exposing (init, update)

import Api.Lenses.RequestIntervalLens as RequestIntervalLens
import Api.Lenses.StatsLens as StatsLens
import Api.Types.Date exposing (Date)
import Api.Types.Stats exposing (Stats)
import Basics.Extra exposing (flip)
import Either
import Http exposing (Error)
import Monocle.Lens as Lens
import Pages.Statistics.Page as Page
import Pages.Statistics.Pagination as Pagination exposing (Pagination)
import Pages.Statistics.Requests as Requests
import Util.HttpUtil as HttpUtil
import Util.Initialization as Initialization


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , requestInterval = RequestIntervalLens.default
      , stats = defaultStats
      , initialization = Initialization.Loading ()
      , pagination = Pagination.initial
      , fetching = False
      }
    , Cmd.none
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

        Page.SetPagination pagination ->
            setPagination model pagination


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


fetchStats : Page.Model -> ( Page.Model, Cmd Page.Msg )
fetchStats model =
    ( model
        |> Page.lenses.fetching.set True
    , Requests.fetchStats model.authorizedAccess model.requestInterval
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
                    |> Page.lenses.fetching.set False
            )
    , Cmd.none
    )


setPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setPagination model pagination =
    ( model |> Page.lenses.pagination.set pagination
    , Cmd.none
    )


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
