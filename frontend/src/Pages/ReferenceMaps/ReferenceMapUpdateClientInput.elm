module Pages.ReferenceMaps.ReferenceMapUpdateClientInput exposing (..)

import Api.Types.ReferenceMap exposing (ReferenceMap)
import Api.Types.ReferenceMapUpdate exposing (ReferenceMapUpdate)
import Api.Types.UUID exposing (UUID)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias ReferenceMapUpdateClientInput =
    { id : UUID
    , name : ValidatedInput String
    }


lenses :
    { name : Lens ReferenceMapUpdateClientInput (ValidatedInput String)
    }
lenses =
    { name = Lens .name (\b a -> { a | name = b })
    }


from : ReferenceMap -> ReferenceMapUpdateClientInput
from referenceMap =
    { id = referenceMap.id
    , name =
        ValidatedInput.nonEmptyString
            |> ValidatedInput.lenses.value.set referenceMap.name
            |> ValidatedInput.lenses.text.set referenceMap.name
    }


to : ReferenceMapUpdateClientInput -> ReferenceMapUpdate
to input =
    { id = input.id
    , name = input.name.value
    }
