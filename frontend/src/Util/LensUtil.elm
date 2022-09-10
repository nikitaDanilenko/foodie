module Util.LensUtil exposing (..)

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
