module Pages.MealEntries.Pagination exposing (..)

import Monocle.Lens exposing (Lens)
import Pages.Util.PaginationSettings as PaginationSettings exposing (PaginationSettings)


type alias Pagination =
    { mealEntries : PaginationSettings
    , recipes : PaginationSettings
    }


initial : Pagination
initial =
    { mealEntries = PaginationSettings.initial
    , recipes = PaginationSettings.initial
    }


lenses :
    { mealEntries : Lens Pagination PaginationSettings
    , recipes : Lens Pagination PaginationSettings
    }
lenses =
    { mealEntries = Lens .mealEntries (\b a -> { a | mealEntries = b })
    , recipes = Lens .recipes (\b a -> { a | recipes = b })
    }
