module Pages.Statistics.Page exposing (..)

import Api.Auxiliary exposing (NutrientCode, ReferenceMapId)
import Api.Lenses.RequestIntervalLens as RequestIntervalLens
import Api.Types.Date exposing (Date)
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Api.Types.RequestInterval exposing (RequestInterval)
import Api.Types.Stats exposing (Stats)
import Dict exposing (Dict)
import Http exposing (Error)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Statistics.Pagination exposing (Pagination)
import Pages.Statistics.Status exposing (Status)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , requestInterval : RequestInterval
    , stats : Stats
    , referenceTrees : Dict ReferenceMapId ReferenceNutrientTree
    , referenceTree : Maybe ReferenceNutrientTree
    , initialization : Initialization Status
    , pagination : Pagination
    , fetching : Bool
    }


lenses :
    { requestInterval : Lens Model RequestInterval
    , from : Lens Model (Maybe Date)
    , to : Lens Model (Maybe Date)
    , stats : Lens Model Stats
    , referenceTrees : Lens Model (Dict ReferenceMapId ReferenceNutrientTree)
    , referenceTree : Lens Model (Maybe ReferenceNutrientTree)
    , initialization : Lens Model (Initialization Status)
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
    , referenceTrees = Lens .referenceTrees (\b a -> { a | referenceTrees = b })
    , referenceTree = Lens .referenceTree (\b a -> { a | referenceTree = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , pagination = Lens .pagination (\b a -> { a | pagination = b })
    , fetching = Lens .fetching (\b a -> { a | fetching = b })
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type alias ReferenceNutrientTree =
    { map : ReferenceMap
    , values : Dict NutrientCode Float
    }


type Msg
    = SetFromDate (Maybe Date)
    | SetToDate (Maybe Date)
    | FetchStats
    | GotFetchStatsResponse (Result Error Stats)
    | GotFetchReferenceTreesResponse (Result Error (List ReferenceTree))
    | SetPagination Pagination
    | SelectReferenceMap (Maybe ReferenceMapId)
