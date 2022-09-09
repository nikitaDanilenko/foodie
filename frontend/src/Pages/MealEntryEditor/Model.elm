module Pages.MealEntryEditor.Model exposing (..)

import Api.Auxiliary exposing (JWT, MealId, RecipeId)
import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.Recipe exposing (Recipe)
import Configuration exposing (Configuration)
import Dict exposing (Dict)
import Either exposing (Either)
import Monocle.Lens exposing (Lens)
import Pages.MealEntryEditor.MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntryEditor.MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Util.Editing exposing (Editing)


type alias Model =
    { configuration : Configuration
    , jwt : JWT
    , mealId : MealId
    , mealEntries : List MealEntryOrUpdate
    , recipes : RecipeMap
    , recipeSearchString : String
    , mealEntriesToAdd : List MealEntryCreationClientInput
    }


type alias MealEntryOrUpdate =
    Either MealEntry (Editing MealEntry MealEntryUpdateClientInput)


type alias RecipeMap =
    Dict RecipeId Recipe


type alias Flags =
    { configuration : Configuration
    , jwt : Maybe JWT
    , mealId : MealId
    }


type alias FlagsWithJWT =
    { configuration : Configuration
    , jwt : JWT
    , mealId : MealId
    }


lenses :
    { jwt : Lens Model JWT
    , mealEntries : Lens Model (List MealEntryOrUpdate)
    , mealEntriesToAdd : Lens Model (List MealEntryCreationClientInput)
    , recipeSearchString : Lens Model String
    }
lenses =
    { jwt = Lens .jwt (\b a -> { a | jwt = b })
    , mealEntries = Lens .mealEntries (\b a -> { a | mealEntries = b })
    , mealEntriesToAdd = Lens .mealEntriesToAdd (\b a -> { a | mealEntriesToAdd = b })
    , recipeSearchString = Lens .recipeSearchString (\b a -> { a | recipeSearchString = b })
    }
