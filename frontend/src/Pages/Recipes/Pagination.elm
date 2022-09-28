module Pages.Recipes.Pagination exposing (..)


import Monocle.Lens exposing (Lens)
import Pages.Util.PaginationSettings as PaginationSettings exposing (PaginationSettings)


type alias Pagination =
    { recipes : PaginationSettings
    }


initial : Pagination
initial =
    { recipes = PaginationSettings.initial
    }


lenses :
    { recipes : Lens Pagination PaginationSettings
    }
lenses =
    { recipes = Lens .recipes (\b a -> { a | recipes = b })
    }
