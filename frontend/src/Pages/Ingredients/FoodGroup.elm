module Pages.Ingredients.FoodGroup exposing (..)

import Dict exposing (Dict)
import Either exposing (Either)
import Monocle.Lens exposing (Lens)
import Pages.Ingredients.Pagination as Pagination exposing (Pagination)
import Util.Editing exposing (Editing)


type alias FoodGroup ingredientId ingredient update foodId food creation =
    { ingredients : Dict ingredientId (IngredientOrUpdate ingredient update)
    , foods : Dict foodId food
    , foodsToAdd : Dict foodId creation
    , pagination : Pagination
    , foodsSearchString : String
    }


type alias IngredientOrUpdate ingredient update =
    Either ingredient (Editing ingredient update)


initial : FoodGroup ingredientId ingredient update foodId food creation
initial =
    { ingredients = Dict.empty
    , foods = Dict.empty
    , foodsToAdd = Dict.empty
    , pagination = Pagination.initial
    , foodsSearchString = ""
    }


lenses :
    { ingredients : Lens (FoodGroup ingredientId ingredient update foodId food creation) (Dict ingredientId (IngredientOrUpdate ingredient update))
    , foods : Lens (FoodGroup ingredientId ingredient update foodId food creation) (Dict foodId food)
    , foodsToAdd : Lens (FoodGroup ingredientId ingredient update foodId food creation) (Dict foodId creation)
    , pagination : Lens (FoodGroup ingredientId ingredient update foodId food creation) Pagination
    , foodsSearchString : Lens (FoodGroup ingredientId ingredient update foodId food creation) String
    }
lenses =
    { ingredients = Lens .ingredients (\b a -> { a | ingredients = b })
    , foods = Lens .foods (\b a -> { a | foods = b })
    , foodsToAdd = Lens .foodsToAdd (\b a -> { a | foodsToAdd = b })
    , pagination = Lens .pagination (\b a -> { a | pagination = b })
    , foodsSearchString = Lens .foodsSearchString (\b a -> { a | foodsSearchString = b })
    }
