module Pages.ReferenceMaps.Pagination exposing (..)

import Monocle.Lens exposing (Lens)
import Pages.Util.PaginationSettings as PaginationSettings exposing (PaginationSettings)


type alias Pagination =
    { referenceMaps : PaginationSettings
    }


initial : Pagination
initial =
    { referenceMaps = PaginationSettings.initial
    }


lenses :
    { referenceMaps : Lens Pagination PaginationSettings
    }
lenses =
    { referenceMaps = Lens .referenceMaps (\b a -> { a | referenceMaps = b })
    }
