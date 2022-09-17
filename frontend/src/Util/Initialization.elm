module Util.Initialization exposing (..)

import Monocle.Optional exposing (Optional)


type Initialization status
    = Loading status
    | Failure ErrorExplanation


type alias ErrorExplanation =
    { cause : String
    , possibleSolution : String
    , redirectToLogin : Bool
    }


lenses :
    { loading : Optional (Initialization status) status
    }
lenses =
    { loading =
        { getOption =
            \initialization ->
                case initialization of
                    Loading status ->
                        Just status

                    _ ->
                        Nothing
        , set =
            \status initialization ->
                case initialization of
                    Loading _ ->
                        Loading status

                    x ->
                        x
        }
    }

