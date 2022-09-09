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
import Pages.MealEntryEditor.Handler as Handler
import Pages.MealEntryEditor.MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntryEditor.MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Ports exposing (doFetchToken)
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
    | UpdateRecipes String
    | SetRecipesSearchString String


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( j, cmd ) =
            case flags.jwt of
                Just token ->
                    ( token
                    , Handler.fetchRecipesRequest
                        { configuration = flags.configuration
                        , jwt = token
                        , mealId = flags.mealId
                        }
                    )

                Nothing ->
                    ( "", doFetchToken () )
    in
    ( { flagsWithJWT =
            { configuration = flags.configuration
            , jwt = j
            , mealId = flags.mealId
            }
      , mealEntries = []
      , recipes = Dict.empty
      , recipeSearchString = ""
      , mealEntriesToAdd = []
      }
    , cmd
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateMealEntry mealEntryUpdateClientInput ->
            Handler.updateMealEntry model mealEntryUpdateClientInput

        SaveMealEntryEdit mealEntryId ->
            Handler.saveMealEntryEdit model mealEntryId

        GotSaveMealEntryResponse result ->
            Handler.gotSaveMealEntryResponse model result

        EnterEditMealEntry mealEntryId ->
            Handler.enterEditMealEntry model mealEntryId

        ExitEditMealEntryAt mealEntryId ->
            Handler.exitEditMealEntryAt model mealEntryId

        DeleteMealEntry mealEntryId ->
            Handler.deleteMealEntry model mealEntryId

        GotDeleteMealEntryResponse mealEntryId result ->
            Handler.gotDeleteMealEntryResponse model mealEntryId result

        GotFetchMealEntriesResponse result ->
            Handler.gotFetchMealEntriesResponse model result

        GotFetchRecipesResponse result ->
            Handler.gotFetchRecipesResponse model result

        SelectRecipe recipe ->
            Handler.selectRecipe model recipe

        DeselectRecipe recipeId ->
            Handler.deselectRecipe model recipeId

        AddRecipe recipeId ->
            Handler.addRecipe model recipeId

        GotAddMealEntryResponse result ->
            Handler.gotAddMealEntryResponse model result

        UpdateAddRecipe mealEntryCreationClientInput ->
            Handler.updateAddRecipe model mealEntryCreationClientInput

        UpdateJWT jwt ->
            Handler.updateJWT model jwt

        UpdateRecipes string ->
            Handler.updateRecipes model string

        SetRecipesSearchString string ->
            Handler.setRecipesSearchString model string


view : Model -> Html Msg
view =
    View.view >> div [ id "mealEntryEditor" ]
