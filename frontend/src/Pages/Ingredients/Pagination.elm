module Pages.Ingredients.Pagination exposing (..)

import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Util.PaginationSettings as PaginationSettings exposing (PaginationSettings)


type alias Pagination =
    { ingredients : PaginationSettings
    , foods : PaginationSettings
    }


initial : Pagination
initial =
    { ingredients = PaginationSettings.initial
    , foods = PaginationSettings.initial
    }


lenses :
    { ingredients : Lens Pagination PaginationSettings
    , foods : Lens Pagination PaginationSettings
    }
lenses =
    { ingredients = Lens .ingredients (\b a -> { a | ingredients = b })
    , foods = Lens .foods (\b a -> { a | foods = b })
    }


updateCurrentPage :
    { a
        | pagination : Lens model pagination
        , items : Lens pagination PaginationSettings
    }
    -> model
    -> Int
    -> pagination
updateCurrentPage ps model =
    \foods ->
        ps.pagination.get model
            |> (ps.items
                    |> Compose.lensWithLens PaginationSettings.lenses.currentPage
               ).set
                foods
