module Pages.MealEntryEditor.Page exposing (..)

import Api.Auxiliary exposing (JWT, MealEntryId, MealId, RecipeId)
import Api.Types.Meal exposing (Meal)
import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Dict exposing (Dict)
import Either exposing (Either)
import Http exposing (Error)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.MealEntryEditor.MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntryEditor.MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Pages.MealEntryEditor.MealInfo exposing (MealInfo)
import Util.Editing exposing (Editing)


type alias Model =
    { flagsWithJWT : FlagsWithJWT
    , mealInfo : Maybe MealInfo
    , mealEntries : List MealEntryOrUpdate
    , recipes : RecipeMap
    , recipesSearchString : String
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
    , mealInfo : Lens Model (Maybe MealInfo)
    , mealEntries : Lens Model (List MealEntryOrUpdate)
    , mealEntriesToAdd : Lens Model (List MealEntryCreationClientInput)
    , recipes : Lens Model RecipeMap
    , recipesSearchString : Lens Model String
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
    , mealInfo = Lens .mealInfo (\b a -> { a | mealInfo = b })
    , mealEntries = Lens .mealEntries (\b a -> { a | mealEntries = b })
    , mealEntriesToAdd = Lens .mealEntriesToAdd (\b a -> { a | mealEntriesToAdd = b })
    , recipes = Lens .recipes (\b a -> { a | recipes = b })
    , recipesSearchString = Lens .recipesSearchString (\b a -> { a | recipesSearchString = b })
    }


recipeNameOrEmpty : RecipeMap -> RecipeId -> String
recipeNameOrEmpty recipeMap =
    flip Dict.get recipeMap >> Maybe.Extra.unwrap "" .name


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
    | GotFetchMealResponse (Result Error Meal)
    | SelectRecipe RecipeId
    | DeselectRecipe RecipeId
    | AddRecipe RecipeId
    | GotAddMealEntryResponse (Result Error MealEntry)
    | UpdateAddRecipe MealEntryCreationClientInput
    | UpdateJWT JWT
    | SetRecipesSearchString String
