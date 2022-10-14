module Pages.Util.SimpleDateInput exposing (..)

import Api.Types.Date exposing (Date)
import Api.Types.SimpleDate exposing (SimpleDate)
import Api.Types.Time exposing (Time)
import Basics.Extra exposing (flip)
import Monocle.Lens exposing (Lens)


type alias SimpleDateInput =
    { date : Maybe Date
    , time : Maybe Time
    }


default : SimpleDateInput
default =
    SimpleDateInput Nothing Nothing


lenses :
    { date : Lens SimpleDateInput (Maybe Date)
    , time : Lens SimpleDateInput (Maybe Time)
    }
lenses =
    { date = Lens .date (\b a -> { a | date = b })
    , time = Lens .time (\b a -> { a | time = b })
    }


from : SimpleDate -> SimpleDateInput
from simpleDate =
    { date = Just simpleDate.date
    , time = simpleDate.time
    }


to : SimpleDateInput -> Maybe SimpleDate
to input =
    input.date
        |> Maybe.map (flip SimpleDate input.time)
