module Api.Lenses.RequestIntervalLens exposing (..)

import Api.Types.Date exposing (Date)
import Api.Types.RequestInterval exposing (RequestInterval)
import Monocle.Lens exposing (Lens)


from : Lens RequestInterval (Maybe Date)
from =
    Lens .from (\b a -> { a | from = b })


to : Lens RequestInterval (Maybe Date)
to =
    Lens .to (\b a -> { a | to = b })


default : RequestInterval
default =
    { from = Nothing
    , to = Nothing
    }
