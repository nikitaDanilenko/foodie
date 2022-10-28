module Pages.Util.DictUtil exposing (..)

import Dict exposing (Dict)
import Maybe.Extra


existsValue : (v -> Bool) -> Dict comparable v -> Bool
existsValue p =
    Dict.filter (always p)
        >> Dict.isEmpty
        >> not


firstSuch : (v -> Bool) -> Dict comparable v -> Maybe v
firstSuch p =
    Dict.filter (always p)
        >> Dict.values
        >> List.head


nameOrEmpty : Dict comparable { a | name : String } -> comparable -> String
nameOrEmpty map id =
    Dict.get id map |> Maybe.Extra.unwrap "" .name
