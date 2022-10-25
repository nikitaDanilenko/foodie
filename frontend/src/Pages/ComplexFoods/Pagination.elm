module Pages.ComplexFoods.Pagination exposing (..)

import Monocle.Lens exposing (Lens)
import Pages.Util.PaginationSettings as PaginationSettings exposing (PaginationSettings)


type alias Pagination =
    { complexFoods : PaginationSettings
    , recipes : PaginationSettings
    }


initial : Pagination
initial =
    { complexFoods = PaginationSettings.initial
    , recipes = PaginationSettings.initial
    }


lenses :
    { complexFoods : Lens Pagination PaginationSettings
    , recipes : Lens Pagination PaginationSettings
    }
lenses =
    { complexFoods = Lens .complexFoods (\b a -> { a | complexFoods = b })
    , recipes = Lens .recipes (\b a -> { a | recipes = b })
    }
