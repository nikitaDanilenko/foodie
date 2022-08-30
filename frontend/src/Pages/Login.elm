module Pages.Login exposing (Model, init, update, view)

import Util.TriState exposing (TriState)


type alias Model =
    { nickname : String
    , password : String
    , state : TriState
    }

nick