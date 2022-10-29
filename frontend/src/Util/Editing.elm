module Util.Editing exposing (..)

import Either exposing (Either)
import Monocle.Lens exposing (Lens)


type alias Editing a b =
    { original : a
    , update : b
    }


lenses :
    { update : Lens (Editing a b) b
    }
lenses =
    { update = Lens .update (\b a -> { a | update = b })
    }


field : (a -> field) -> Either a (Editing a b) -> field
field f =
    Either.unpack f (.original >> f)
