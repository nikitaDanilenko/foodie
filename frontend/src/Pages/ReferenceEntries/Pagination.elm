module Pages.ReferenceEntries.Pagination exposing (..)

import Monocle.Lens exposing (Lens)
import Pages.Util.PaginationSettings as PaginationSettings exposing (PaginationSettings)


type alias Pagination =
    { referenceEntries : PaginationSettings
    , nutrients : PaginationSettings
    }


initial : Pagination
initial =
    { referenceEntries = PaginationSettings.initial
    , nutrients = PaginationSettings.initial
    }


lenses :
    { referenceEntries : Lens Pagination PaginationSettings
    , nutrients : Lens Pagination PaginationSettings
    }
lenses =
    { referenceEntries = Lens .referenceEntries (\b a -> { a | referenceEntries = b })
    , nutrients = Lens .nutrients (\b a -> { a | nutrients = b })
    }


