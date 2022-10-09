module Addresses.Backend exposing (..)

import Api.Auxiliary exposing (IngredientId, MealEntryId, MealId, NutrientCode, RecipeId)
import Maybe.Extra
import Url.Builder exposing (QueryParameter)
import Util.HttpUtil as HttpUtil exposing (ResourcePattern)


recipes :
    { measures : ResourcePattern
    , foods : ResourcePattern
    , all : ResourcePattern
    , single : RecipeId -> ResourcePattern
    , create : ResourcePattern
    , update : ResourcePattern
    , delete : RecipeId -> ResourcePattern
    , ingredients :
        { allOf : RecipeId -> ResourcePattern
        , create : ResourcePattern
        , update : ResourcePattern
        , delete : IngredientId -> ResourcePattern
        }
    }
recipes =
    let
        base =
            (::) "recipes"

        ingredientsWord =
            "ingredients"

        ingredients =
            (::) ingredientsWord >> base
    in
    { measures = get <| base <| [ "measures" ]
    , foods = get <| base <| [ "foods" ]
    , all = get <| base <| []
    , single = \recipeId -> get <| base <| [ recipeId ]
    , create = post <| base []
    , update = patch <| base []
    , delete = \recipeId -> delete <| base <| [ recipeId ]
    , ingredients =
        { allOf = \recipeId -> get <| base <| [ recipeId, ingredientsWord ]
        , create = post <| ingredients []
        , update = patch <| ingredients []
        , delete = \ingredientId -> delete <| ingredients <| [ ingredientId ]
        }
    }


meals :
    { all : ResourcePattern
    , single : MealId -> ResourcePattern
    , create : ResourcePattern
    , update : ResourcePattern
    , delete : MealId -> ResourcePattern
    , entries :
        { allOf : MealId -> ResourcePattern
        , create : ResourcePattern
        , update : ResourcePattern
        , delete : MealEntryId -> ResourcePattern
        }
    }
meals =
    let
        base =
            (::) "meals"

        entriesWord =
            "entries"

        entries =
            (::) entriesWord >> base
    in
    { all = get <| base <| []
    , single = \mealId -> get <| base <| [ mealId ]
    , create = post <| base []
    , update = patch <| base []
    , delete = \mealId -> delete <| base <| [ mealId ]
    , entries =
        { allOf = \mealId -> get <| base <| [ mealId, entriesWord ]
        , create = post <| entries []
        , update = patch <| entries []
        , delete = \mealEntryId -> delete <| entries <| [ mealEntryId ]
        }
    }


stats :
    { all :
        { from : Maybe QueryParameter
        , to : Maybe QueryParameter
        }
        -> ResourcePattern
    , nutrients : ResourcePattern
    , references :
        { all : ResourcePattern
        , create : ResourcePattern
        , update : ResourcePattern
        , delete : NutrientCode -> ResourcePattern
        }
    }
stats =
    let
        base =
            (::) "stats"

        references =
            (::) "references" >> base
    in
    { all = \interval -> getQ (base []) (Maybe.Extra.values [ interval.from, interval.to ])
    , nutrients = get <| base <| [ "nutrients" ]
    , references =
        { all = get <| references <| []
        , create = post <| references <| []
        , update = patch <| references <| []
        , delete = \nutrientCode -> delete <| references <| [ nutrientCode |> String.fromInt ]
        }
    }


users :
    { login : ResourcePattern
    , logout : ResourcePattern
    , update : ResourcePattern
    , get : ResourcePattern
    , updatePassword : ResourcePattern
    , registration :
        { request : ResourcePattern
        , confirm : ResourcePattern
        }
    , recovery :
        { request : ResourcePattern
        , confirm : ResourcePattern
        , find : String -> ResourcePattern
        }
    , deletion :
        { request : ResourcePattern
        , confirm : ResourcePattern
        }
    }
users =
    let
        base =
            (::) "users"

        registration =
            (::) "registration" >> base

        recovery =
            (::) "recovery" >> base

        deletion =
            (::) "deletion" >> base
    in
    { login = post <| base <| [ "login" ]
    , logout = post <| base <| [ "logout" ]
    , update = patch <| base <| []
    , get = get <| base <| []
    , updatePassword = patch <| base <| [ "password" ]
    , registration =
        { request = post <| registration <| [ "request" ]
        , confirm = post <| registration <| [ "confirm" ]
        }
    , recovery =
        { request = post <| recovery <| [ "request" ]
        , confirm = post <| recovery <| [ "confirm" ]
        , find = \searchString -> get <| recovery <| [ "find", searchString ]
        }
    , deletion =
        { request = post <| deletion <| [ "request" ]
        , confirm = post <| deletion <| [ "confirm" ]
        }
    }


pattern : HttpUtil.Verb -> List String -> ResourcePattern
pattern verb path =
    { verb = verb
    , address = path
    , query = []
    }


get : List String -> ResourcePattern
get =
    pattern HttpUtil.GET


getQ : List String -> List QueryParameter -> ResourcePattern
getQ =
    ResourcePattern HttpUtil.GET


patch : List String -> ResourcePattern
patch =
    pattern HttpUtil.PATCH


post : List String -> ResourcePattern
post =
    pattern HttpUtil.POST


delete : List String -> ResourcePattern
delete =
    pattern HttpUtil.DELETE
