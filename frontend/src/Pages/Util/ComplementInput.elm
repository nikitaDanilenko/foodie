module Pages.Util.ComplementInput exposing (..)

import Monocle.Lens exposing (Lens)


type alias ComplementInput =
    { displayName : Maybe String
    , password1 : String
    , password2 : String
    }


initial : ComplementInput
initial =
    { displayName = Nothing
    , password1 = ""
    , password2 = ""
    }


lenses :
    { displayName : Lens ComplementInput (Maybe String)
    , password1 : Lens ComplementInput String
    , password2 : Lens ComplementInput String
    }
lenses =
    { displayName = Lens .displayName (\b a -> { a | displayName = b })
    , password1 = Lens .password1 (\b a -> { a | password1 = b })
    , password2 = Lens .password2 (\b a -> { a | password2 = b })
    }
