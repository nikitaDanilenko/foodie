module Util.ListUtil exposing (..)

import List.Extra


insertBy :
    { compareA : a -> comparable
    , compareB : b -> comparable
    , mapAB : a -> b
    , replace : Bool
    }
    -> a
    -> List b
    -> List b
insertBy ps x list =
    case List.Extra.uncons list of
        Nothing ->
            [ ps.mapAB x ]

        Just ( e, es ) ->
          let cmpB = ps.compareB e
              cmpA = ps.compareA x
          in
            if cmpB < cmpA then
                e :: insertBy ps x es

            else if cmpB == cmpA then
              ps.mapAB x :: if ps.replace then es else list

            else
                ps.mapAB x :: list
