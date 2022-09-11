module Pages.Statistics.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Api.Types.Date exposing (Date)
import Api.Types.RequestInterval exposing (RequestInterval)
import Api.Types.Stats exposing (Stats)
import Configuration exposing (Configuration)
import Http exposing (Error)
import Monocle.Lens exposing (Lens)
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Util.LensUtil as LensUtil


type alias Model =
    { flagsWithJWT : FlagsWithJWT
    , requestInterval: RequestInterval
    , stats : Stats
    }


lenses :
    { jwt : Lens Model JWT
    , requestInterval : Lens Model RequestInterval
    , stats : Lens Model Stats
    }
lenses =
    { jwt = LensUtil.jwtSubLens
    , requestInterval = Lens .requestInterval (\b a -> { a | requestInterval = b })
    , stats = Lens .stats (\b a -> { a | stats = b })
    }


type alias Flags =
    { configuration : Configuration
    , jwt : Maybe String
    }


type Msg
    = SetStartDate (Maybe Date)
    | SetEndDate (Maybe Date)
    | FetchStats
    | GotFetchStatsResponse (Result Error Stats)
    | UpdateJWT JWT
