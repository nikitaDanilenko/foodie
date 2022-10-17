module Pages.Statistics.Page exposing (..)

import Api.Lenses.RequestIntervalLens as RequestIntervalLens
import Api.Types.Date exposing (Date)
import Api.Types.RequestInterval exposing (RequestInterval)
import Api.Types.Stats exposing (Stats)
import Http exposing (Error)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Statistics.Pagination exposing (Pagination)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , requestInterval : RequestInterval
    , stats : Stats
    , initialization : Initialization ()
    , pagination : Pagination
    , fetching: Bool
    }


lenses :
    { requestInterval : Lens Model RequestInterval
    , from : Lens Model (Maybe Date)
    , to : Lens Model (Maybe Date)
    , stats : Lens Model Stats
    , initialization : Lens Model (Initialization ())
    , pagination : Lens Model Pagination
    , fetching : Lens Model Bool
    }
lenses =
    let
        requestInterval =
            Lens .requestInterval (\b a -> { a | requestInterval = b })
    in
    { requestInterval = requestInterval
    , from = requestInterval |> Compose.lensWithLens RequestIntervalLens.from
    , to = requestInterval |> Compose.lensWithLens RequestIntervalLens.to
    , stats = Lens .stats (\b a -> { a | stats = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , pagination = Lens .pagination (\b a -> { a | pagination = b })
    , fetching = Lens .fetching (\b a -> { a | fetching = b })
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type Msg
    = SetFromDate (Maybe Date)
    | SetToDate (Maybe Date)
    | FetchStats
    | GotFetchStatsResponse (Result Error Stats)
    | SetPagination Pagination
