module Pages.IngredientEditor.AmountUnitClientInput exposing (..)

import Api.Auxiliary exposing (MeasureId)
import Api.Types.AmountUnit exposing (AmountUnit)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias AmountUnitClientInput =
    { measureId : MeasureId
    , factor : ValidatedInput Float
    }


default : MeasureId -> AmountUnitClientInput
default mId =
    { measureId = mId
    , factor = ValidatedInput.positive
    }


from : AmountUnit -> AmountUnitClientInput
from au =
    { measureId = au.measureId
    , factor = ValidatedInput.value.set au.factor ValidatedInput.positive
    }


to : AmountUnitClientInput -> AmountUnit
to input =
    { measureId = input.measureId
    , factor = input.factor.value
    }


measureId : Lens AmountUnitClientInput MeasureId
measureId =
    Lens .measureId (\b a -> { a | measureId = b })


factor : Lens AmountUnitClientInput (ValidatedInput Float)
factor =
    Lens .factor (\b a -> { a | factor = b })
