module Util.LensUtil exposing (..)

import Basics.Extra exposing (flip)
import Dict exposing (Dict)
import List.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)


firstSuch : (a -> Bool) -> Optional (List a) a
firstSuch p =
    { getOption = List.Extra.find p
    , set = List.Extra.setIf p
    }


flagsWithJWTLens : Lens { a | flagsWithJWT : b } b
flagsWithJWTLens =
    Lens .flagsWithJWT (\b a -> { a | flagsWithJWT = b })


jwtLens : Lens { a | jwt : b } b
jwtLens =
    Lens .jwt (\b a -> { a | jwt = b })


jwtSubLens : Lens { a | flagsWithJWT : { b | jwt : c } } c
jwtSubLens =
    flagsWithJWTLens |> Compose.lensWithLens jwtLens


set : List a -> (a -> comparable) -> Lens model (Dict comparable a) -> model -> model
set xs idOf lens md =
    xs
        |> List.map (\m -> ( idOf m, m ))
        |> Dict.fromList
        |> flip lens.set md
