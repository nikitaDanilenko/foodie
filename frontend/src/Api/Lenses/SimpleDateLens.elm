module Api.Lenses.SimpleDateLens exposing (..)

import Api.Types.Date exposing (Date)
import Api.Types.SimpleDate exposing (SimpleDate)
import Api.Types.Time exposing (Time)
import Monocle.Lens exposing (Lens)


date : Lens SimpleDate Date
date =
    Lens .date (\b a -> { a | date = b })


time : Lens SimpleDate (Maybe Time)
time =
    Lens .time (\b a -> { a | time = b })
