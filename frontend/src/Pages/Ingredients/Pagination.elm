module Pages.Ingredients.Pagination exposing (..)

import Monocle.Lens exposing (Lens)



-- todo: Consider parametric variant, where the sizes are configurable


type alias Pagination =
    { ingredients : Int
    , foods : Int
    }


initial : Pagination
initial =
    { ingredients = 1
    , foods = 1
    }


lenses :
    { ingredients : Lens Pagination Int
    , foods : Lens Pagination Int
    }
lenses =
    { ingredients = Lens .ingredients (\b a -> { a | ingredients = b })
    , foods = Lens .foods (\b a -> { a | foods = b })
    }
