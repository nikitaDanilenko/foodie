module Api.Lenses.AmountUnitLens exposing (..)

import Api.Auxiliary exposing (MeasureId)
import Api.Types.AmountUnit exposing (AmountUnit)
import Monocle.Lens exposing (Lens)


measureId : Lens AmountUnit MeasureId
measureId =
    Lens .measureId (\b a -> { a | measureId = b })


factor : Lens AmountUnit Float
factor =
    Lens .factor (\b a -> { a | factor = b })