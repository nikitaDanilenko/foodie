module Pages.Statistics.Requests exposing (fetchStats)

import Api.Types.RequestInterval exposing (RequestInterval)
import Api.Types.Stats exposing (decoderStats)
import Maybe.Extra
import Pages.Statistics.Page as Page
import Pages.Util.DateUtil as DateUtil
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Url.Builder exposing (string)
import Util.HttpUtil as HttpUtil


fetchStats : FlagsWithJWT -> RequestInterval -> Cmd Page.Msg
fetchStats flags requestInterval =
    let
        toQuery name =
            Maybe.map (DateUtil.dateToString >> Url.Builder.string name)

        query =
            [ requestInterval.from |> toQuery "from"
            , requestInterval.to |> toQuery "to"
            ]
                |> Maybe.Extra.values
    in
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "stats" ] query
        , expect = HttpUtil.expectJson Page.GotFetchStatsResponse decoderStats
        }
