module Pages.Ingredients.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { foods : Bool
    , complexFoods : Bool
    , measures : Bool
    , ingredients : Bool
    , complexIngredients : Bool
    , recipe : Bool
    }


initial : Status
initial =
    { foods = False
    , complexFoods = False
    , measures = False
    , ingredients = False
    , complexIngredients = False
    , recipe = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.foods
        , status.complexFoods
        , status.measures
        , status.ingredients
        , status.complexIngredients
        ]


lenses :
    { foods : Lens Status Bool
    , complexFoods : Lens Status Bool
    , measures : Lens Status Bool
    , ingredients : Lens Status Bool
    , complexIngredients : Lens Status Bool
    , recipe : Lens Status Bool
    }
lenses =
    { foods = Lens .foods (\b a -> { a | foods = b })
    , complexFoods = Lens .complexFoods (\b a -> { a | complexFoods = b })
    , measures = Lens .measures (\b a -> { a | measures = b })
    , ingredients = Lens .ingredients (\b a -> { a | ingredients = b })
    , complexIngredients = Lens .complexIngredients (\b a -> { a | complexIngredients = b })
    , recipe = Lens .recipe (\b a -> { a | recipe = b })
    }
