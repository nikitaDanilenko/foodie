module Pages.Statistics.Requests exposing (fetchStats)

import Addresses.Backend
import Api.Types.RequestInterval exposing (RequestInterval)
import Api.Types.Stats exposing (decoderStats)
import Http
import Pages.Statistics.Page as Page
import Pages.Util.DateUtil as DateUtil
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Url.Builder
import Util.HttpUtil as HttpUtil


fetchStats : FlagsWithJWT -> RequestInterval -> Cmd Page.Msg
fetchStats flags requestInterval =
    let
        toQuery name =
            Maybe.map (DateUtil.dateToString >> Url.Builder.string name)

        interval =
            { from = requestInterval.from |> toQuery "from"
            , to = requestInterval.to |> toQuery "to"
            }
    in
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.stats.all interval)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchStatsResponse decoderStats
        }
