module Pages.ReferenceNutrients.Pagination exposing (..)

import Monocle.Lens exposing (Lens)
import Pages.Util.PaginationSettings as PaginationSettings exposing (PaginationSettings)


type alias Pagination =
    { referenceNutrients : PaginationSettings
    , nutrients : PaginationSettings
    }


initial : Pagination
initial =
    { referenceNutrients = PaginationSettings.initial
    , nutrients = PaginationSettings.initial
    }


lenses :
    { referenceNutrients : Lens Pagination PaginationSettings
    , nutrients : Lens Pagination PaginationSettings
    }
lenses =
    { referenceNutrients = Lens .referenceNutrients (\b a -> { a | referenceNutrients = b })
    , nutrients = Lens .nutrients (\b a -> { a | nutrients = b })
    }


