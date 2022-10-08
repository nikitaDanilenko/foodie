module Pages.Util.InitUtil exposing (..)

import Api.Auxiliary exposing (JWT)
import Maybe.Extra
import Ports


fetchIfEmpty : Maybe JWT -> (JWT -> Cmd msg) -> ( JWT, Cmd msg )
fetchIfEmpty jwt whenToken =
    jwt
        |> Maybe.Extra.unwrap
            ( "", Ports.doFetchToken () )
            (\token ->
                ( token
                , whenToken token
                )
            )
