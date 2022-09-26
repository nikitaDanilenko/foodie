module Pages.Util.PaginationSettings exposing (..)

import Monocle.Lens exposing (Lens)


type alias PaginationSettings =
    { currentPage : Int
    , itemsPerPage : Int
    }


initial : PaginationSettings
initial =
    { currentPage = 1
    , itemsPerPage = 25
    }


lenses :
    { currentPage : Lens PaginationSettings Int
    , itemsPerPage : Lens PaginationSettings Int
    }
lenses =
    { currentPage = Lens .currentPage (\b a -> { a | currentPage = b })
    , itemsPerPage = Lens .itemsPerPage (\b a -> { a | itemsPerPage = b })
    }
