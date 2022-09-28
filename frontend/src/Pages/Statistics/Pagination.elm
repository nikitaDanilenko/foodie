module Pages.Statistics.Pagination exposing (..)

import Monocle.Lens exposing (Lens)
import Pages.Util.PaginationSettings as PaginationSettings exposing (PaginationSettings)


type alias Pagination =
    { meals : PaginationSettings
    }


initial : Pagination
initial =
    { meals = PaginationSettings.initial
    }


lenses :
    { meals : Lens Pagination PaginationSettings
    }
lenses =
    { meals = Lens .meals (\b a -> { a | meals = b })
    }
