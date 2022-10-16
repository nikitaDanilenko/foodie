module Pages.Ingredients.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { foods : Bool
    , measures : Bool
    , ingredients : Bool
    , recipe : Bool
    }


initial : Status
initial =
    { foods = False
    , measures = False
    , ingredients = False
    , recipe = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.foods
        , status.measures
        , status.ingredients
        ]


lenses :
    { foods : Lens Status Bool
    , measures : Lens Status Bool
    , ingredients : Lens Status Bool
    , recipe : Lens Status Bool
    }
lenses =
    { foods = Lens .foods (\b a -> { a | foods = b })
    , measures = Lens .measures (\b a -> { a | measures = b })
    , ingredients = Lens .ingredients (\b a -> { a | ingredients = b })
    , recipe = Lens .recipe (\b a -> { a | recipe = b })
    }
