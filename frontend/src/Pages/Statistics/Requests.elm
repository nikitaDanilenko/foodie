module Pages.Statistics.Requests exposing (fetchStats)

import Addresses.Backend
import Api.Types.RequestInterval exposing (RequestInterval)
import Api.Types.Stats exposing (decoderStats)
import Http
import Pages.Statistics.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.DateUtil as DateUtil
import Url.Builder
import Util.HttpUtil as HttpUtil


fetchStats : AuthorizedAccess -> RequestInterval -> Cmd Page.Msg
fetchStats authorizedAccess requestInterval =
    let
        toQuery name =
            Maybe.map (DateUtil.dateToString >> Url.Builder.string name)

        interval =
            { from = requestInterval.from |> toQuery "from"
            , to = requestInterval.to |> toQuery "to"
            }
    in
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.stats.all interval)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchStatsResponse decoderStats
        }
