module Pages.MealEntries.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { mealEntries : Bool
    , meal : Bool
    , recipes : Bool
    }


initial : Status
initial =
    { mealEntries = False
    , meal = False
    , recipes = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.mealEntries
        , status.meal
        , status.recipes
        ]


lenses :
    { mealEntries : Lens Status Bool
    , meal : Lens Status Bool
    , recipes : Lens Status Bool
    }
lenses =
    { mealEntries = Lens .mealEntries (\b a -> { a | mealEntries = b })
    , meal = Lens .meal (\b a -> { a | meal = b })
    , recipes = Lens .recipes (\b a -> { a | recipes = b })
    }
