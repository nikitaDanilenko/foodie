module Pages.IngredientEditor.AmountUnitClientInput exposing (..)

import Api.Auxiliary exposing (MeasureId)
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


measureId : Lens AmountUnitClientInput MeasureId
measureId =
    Lens .measureId (\b a -> { a | measureId = b })


factor : Lens AmountUnitClientInput (ValidatedInput Float)
factor =
    Lens .factor (\b a -> { a | factor = b })
