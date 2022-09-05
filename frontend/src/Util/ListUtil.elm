module Util.ListUtil exposing (..)

import List.Extra


insertBy :
    { compareA : a -> comparable
    , compareB : b -> comparable
    , mapAB : a -> b
    }
    -> a
    -> List b
    -> List b
insertBy ps x list =
    case List.Extra.uncons list of
        Nothing ->
            [ ps.mapAB x ]

        Just ( e, es ) ->
            if ps.compareA e < ps.compareB x then
                e :: insertBy ps x es

            else
                f x :: list
