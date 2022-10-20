module Pages.ReferenceMaps.ReferenceMapCreationClientInput exposing (..)

import Api.Types.ReferenceMapCreation exposing (ReferenceMapCreation)
import Monocle.Lens exposing (Lens)
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)


type alias ReferenceMapCreationClientInput =
    { name : ValidatedInput String
    }


default : ReferenceMapCreationClientInput
default =
    { name = ValidatedInput.nonEmptyString
    }


lenses :
    { name : Lens ReferenceMapCreationClientInput (ValidatedInput String)
    }
lenses =
    { name = Lens .name (\b a -> { a | name = b })
    }


toCreation : ReferenceMapCreationClientInput -> ReferenceMapCreation
toCreation input =
    { name = input.name.value
    }
