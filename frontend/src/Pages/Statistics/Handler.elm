module Pages.Statistics.Handler exposing (init, update)

import Api.Auxiliary exposing (ReferenceMapId)
import Api.Lenses.RequestIntervalLens as RequestIntervalLens
import Api.Lenses.StatsLens as StatsLens
import Api.Types.Date exposing (Date)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Api.Types.Stats exposing (Stats)
import Basics.Extra exposing (flip)
import Dict
import Either
import Http exposing (Error)
import Monocle.Lens as Lens
import Pages.Statistics.Page as Page
import Pages.Statistics.Pagination as Pagination exposing (Pagination)
import Pages.Statistics.Requests as Requests
import Pages.Statistics.Status as Status
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil as HttpUtil
import Util.Initialization as Initialization


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , requestInterval = RequestIntervalLens.default
      , stats = defaultStats
      , referenceTrees = Dict.empty
      , referenceTree = Nothing
      , initialization = Initialization.Loading Status.initial
      , pagination = Pagination.initial
      , fetching = False
      }
    , initialFetch flags.authorizedAccess
    )


initialFetch : AuthorizedAccess -> Cmd Page.Msg
initialFetch =
    Requests.fetchReferenceTrees


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

        Page.GotFetchReferenceTreesResponse result ->
            gotFetchReferenceTreesResponse model result

        Page.SetPagination pagination ->
            setPagination model pagination

        Page.SelectReferenceMap referenceMapId ->
            selectReferenceMap model referenceMapId


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


gotFetchReferenceTreesResponse : Page.Model -> Result Error (List ReferenceTree) -> ( Page.Model, Cmd Page.Msg )
gotFetchReferenceTreesResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\referenceTrees ->
                let
                    referenceNutrientTrees =
                        referenceTrees
                            |> List.map
                                (\referenceTree ->
                                    ( referenceTree.referenceMap.id
                                    , { map = referenceTree.referenceMap
                                      , values =
                                            referenceTree.nutrients
                                                |> List.map
                                                    (\referenceValue ->
                                                        ( referenceValue.nutrientCode, referenceValue.referenceAmount )
                                                    )
                                                |> Dict.fromList
                                      }
                                    )
                                )
                            |> Dict.fromList
                in
                model
                    |> Page.lenses.referenceTrees.set referenceNutrientTrees
            )
    , Cmd.none
    )


setPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setPagination model pagination =
    ( model |> Page.lenses.pagination.set pagination
    , Cmd.none
    )


selectReferenceMap : Page.Model -> Maybe ReferenceMapId -> ( Page.Model, Cmd Page.Msg )
selectReferenceMap model referenceMapId =
    ( referenceMapId
        |> Maybe.andThen (flip Dict.get model.referenceTrees)
        |> flip Page.lenses.referenceTree.set model
    , Cmd.none
    )


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
