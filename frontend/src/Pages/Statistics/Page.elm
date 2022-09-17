module Pages.Statistics.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Api.Lenses.RequestIntervalLens as RequestIntervalLens
import Api.Types.Date exposing (Date)
import Api.Types.RequestInterval exposing (RequestInterval)
import Api.Types.Stats exposing (Stats)
import Configuration exposing (Configuration)
import Http exposing (Error)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Statistics.Status exposing (Status)
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Util.Initialization exposing (Initialization)
import Util.LensUtil as LensUtil


type alias Model =
    { flagsWithJWT : FlagsWithJWT
    , requestInterval : RequestInterval
    , stats : Stats
    , initialization : Initialization Status
    }


lenses :
    { jwt : Lens Model JWT
    , requestInterval : Lens Model RequestInterval
    , from : Lens Model (Maybe Date)
    , to : Lens Model (Maybe Date)
    , stats : Lens Model Stats
    , initialization : Lens Model (Initialization Status)
    }
lenses =
    let
        requestInterval =
            Lens .requestInterval (\b a -> { a | requestInterval = b })
    in
    { jwt = LensUtil.jwtSubLens
    , requestInterval = requestInterval
    , from = requestInterval |> Compose.lensWithLens RequestIntervalLens.from
    , to = requestInterval |> Compose.lensWithLens RequestIntervalLens.to
    , stats = Lens .stats (\b a -> { a | stats = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    }


type alias Flags =
    { configuration : Configuration
    , jwt : Maybe String
    }


type Msg
    = SetFromDate (Maybe Date)
    | SetToDate (Maybe Date)
    | FetchStats
    | GotFetchStatsResponse (Result Error Stats)
    | UpdateJWT JWT
