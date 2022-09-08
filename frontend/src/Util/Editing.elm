module Util.Editing exposing (..)

import Either exposing (Either)
import Monocle.Lens exposing (Lens)


type alias Editing a b =
    { original : a
    , update : b
    }


updateLens : Lens (Editing a b) b
updateLens =
    Lens .update (\b a -> { a | update = b })


is : (a -> field) -> field -> Either a (Editing a b) -> Bool
is fieldOf field =
    Either.unpack
        (\p -> fieldOf p == field)
        (\e -> fieldOf e.original == field)
