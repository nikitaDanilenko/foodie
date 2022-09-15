module Pages.Util.DictUtil exposing (..)

import Dict exposing (Dict)


existsValue : (v -> Bool) -> Dict comparable v -> Bool
existsValue p =
    Dict.filter (always p)
        >> Dict.isEmpty
        >> not
