module Pages.MealEntries.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { jwt : Bool
    , mealEntries : Bool
    , meal : Bool
    , recipes : Bool
    }


initial : Status
initial =
    { jwt = False
    , mealEntries = False
    , meal = False
    , recipes = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.jwt
        , status.mealEntries
        , status.meal
        , status.recipes
        ]


lenses :
    { jwt : Lens Status Bool
    , mealEntries : Lens Status Bool
    , meal : Lens Status Bool
    , recipes : Lens Status Bool
    }
lenses =
    { jwt = Lens .jwt (\b a -> { a | jwt = b })
    , mealEntries = Lens .mealEntries (\b a -> { a | mealEntries = b })
    , meal = Lens .meal (\b a -> { a | meal = b })
    , recipes = Lens .recipes (\b a -> { a | recipes = b })
    }
