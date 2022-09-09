module Pages.MealEntryEditor.Page exposing (..)

import Api.Auxiliary exposing (JWT, MealEntryId, MealId, RecipeId)
import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.Recipe exposing (Recipe)
import Configuration exposing (Configuration)
import Dict exposing (Dict)
import Either exposing (Either)
import Html exposing (Html, div)
import Html.Attributes exposing (id)
import Http exposing (Error)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.MealEntryEditor.MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntryEditor.MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Util.Editing exposing (Editing)


type alias Model =
    { flagsWithJWT : FlagsWithJWT
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
    , recipes : Lens Model RecipeMap
    , recipeSearchString : Lens Model String
    }
lenses =
    { jwt =
        let
            flagsLens =
                Lens .flagsWithJWT (\b a -> { a | flagsWithJWT = b })

            jwtLens =
                Lens .jwt (\b a -> { a | jwt = b })
        in
        flagsLens |> Compose.lensWithLens jwtLens
    , mealEntries = Lens .mealEntries (\b a -> { a | mealEntries = b })
    , mealEntriesToAdd = Lens .mealEntriesToAdd (\b a -> { a | mealEntriesToAdd = b })
    , recipes = Lens .recipes (\b a -> { a | recipes = b })
    , recipeSearchString = Lens .recipeSearchString (\b a -> { a | recipeSearchString = b })
    }


type Msg
    = UpdateMealEntry MealEntryUpdateClientInput
    | SaveMealEntryEdit MealEntryId
    | GotSaveMealEntryResponse (Result Error MealEntry)
    | EnterEditMealEntry MealEntryId
    | ExitEditMealEntryAt MealEntryId
    | DeleteMealEntry MealEntryId
    | GotDeleteMealEntryResponse MealEntryId (Result Error ())
    | GotFetchMealEntriesResponse (Result Error (List MealEntry))
    | GotFetchRecipesResponse (Result Error (List Recipe))
    | SelectRecipe RecipeId
    | DeselectRecipe RecipeId
    | AddRecipe RecipeId
    | GotAddMealEntryResponse (Result Error MealEntry)
    | UpdateAddRecipe MealEntryCreationClientInput
    | UpdateJWT JWT
    | SetRecipesSearchString String
