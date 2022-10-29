module Pages.MealEntries.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT, MealEntryId, MealId, RecipeId)
import Api.Types.Meal exposing (Meal)
import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Dict
import Either exposing (Either(..))
import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Monocle.Optional
import Pages.MealEntries.MealEntryCreationClientInput as MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntries.MealEntryUpdateClientInput as MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Pages.MealEntries.MealInfo as MealInfo
import Pages.MealEntries.Page as Page exposing (Msg(..))
import Pages.MealEntries.Pagination as Pagination exposing (Pagination)
import Pages.MealEntries.Requests as Requests
import Pages.MealEntries.Status as Status
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.PaginationSettings as PaginationSettings
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization(..))
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , mealId = flags.mealId
      , mealInfo = Nothing
      , mealEntries = Dict.empty
      , recipes = Dict.empty
      , recipesSearchString = ""
      , entriesSearchString = ""
      , mealEntriesToAdd = Dict.empty
      , initialization = Loading Status.initial
      , pagination = Pagination.initial
      }
    , initialFetch
        flags.authorizedAccess
        flags.mealId
    )


initialFetch : AuthorizedAccess -> MealId -> Cmd Page.Msg
initialFetch authorizedAccess mealId =
    Cmd.batch
        [ Requests.fetchMeal authorizedAccess mealId
        , Requests.fetchRecipes authorizedAccess
        , Requests.fetchMealEntries authorizedAccess mealId
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        UpdateMealEntry mealEntryUpdateClientInput ->
            updateMealEntry model mealEntryUpdateClientInput

        SaveMealEntryEdit mealEntryUpdateClientInput ->
            saveMealEntryEdit model mealEntryUpdateClientInput

        GotSaveMealEntryResponse result ->
            gotSaveMealEntryResponse model result

        EnterEditMealEntry mealEntryId ->
            enterEditMealEntry model mealEntryId

        ExitEditMealEntryAt mealEntryId ->
            exitEditMealEntryAt model mealEntryId

        DeleteMealEntry mealEntryId ->
            deleteMealEntry model mealEntryId

        GotDeleteMealEntryResponse mealEntryId result ->
            gotDeleteMealEntryResponse model mealEntryId result

        GotFetchMealEntriesResponse result ->
            gotFetchMealEntriesResponse model result

        GotFetchRecipesResponse result ->
            gotFetchRecipesResponse model result

        GotFetchMealResponse result ->
            gotFetchMealResponse model result

        SelectRecipe recipe ->
            selectRecipe model recipe

        DeselectRecipe recipeId ->
            deselectRecipe model recipeId

        AddRecipe recipeId ->
            addRecipe model recipeId

        GotAddMealEntryResponse result ->
            gotAddMealEntryResponse model result

        UpdateAddRecipe mealEntryCreationClientInput ->
            updateAddRecipe model mealEntryCreationClientInput

        SetRecipesSearchString string ->
            setRecipesSearchString model string

        SetEntriesSearchString string ->
            setEntriesSearchString model string

        SetPagination pagination ->
            setPagination model pagination


updateMealEntry : Page.Model -> MealEntryUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
updateMealEntry model mealEntryUpdateClientInput =
    ( model
        |> mapMealEntryOrUpdateById mealEntryUpdateClientInput.mealEntryId
            (Either.mapRight (Editing.lenses.update.set mealEntryUpdateClientInput))
    , Cmd.none
    )


saveMealEntryEdit : Page.Model -> MealEntryUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
saveMealEntryEdit model mealEntryUpdateClientInput =
    ( model
    , mealEntryUpdateClientInput
        |> MealEntryUpdateClientInput.to
        |> Requests.saveMealEntry model.authorizedAccess
    )


gotSaveMealEntryResponse : Page.Model -> Result Error MealEntry -> ( Page.Model, Cmd Page.Msg )
gotSaveMealEntryResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\mealEntry ->
                model
                    |> mapMealEntryOrUpdateById mealEntry.id
                        (always (Left mealEntry))
                    |> Lens.modify Page.lenses.mealEntriesToAdd (Dict.remove mealEntry.recipeId)
            )
    , Cmd.none
    )


enterEditMealEntry : Page.Model -> MealEntryId -> ( Page.Model, Cmd Page.Msg )
enterEditMealEntry model mealEntryId =
    ( model
        |> mapMealEntryOrUpdateById mealEntryId
            (Either.andThenLeft
                (\mealEntry ->
                    Right
                        { original = mealEntry
                        , update = MealEntryUpdateClientInput.from mealEntry
                        }
                )
            )
    , Cmd.none
    )


exitEditMealEntryAt : Page.Model -> MealEntryId -> ( Page.Model, Cmd Page.Msg )
exitEditMealEntryAt model mealEntryId =
    ( model
        |> mapMealEntryOrUpdateById mealEntryId (Either.andThen (.original >> Left))
    , Cmd.none
    )


deleteMealEntry : Page.Model -> MealEntryId -> ( Page.Model, Cmd Page.Msg )
deleteMealEntry model mealEntryId =
    ( model
    , Requests.deleteMealEntry model.authorizedAccess mealEntryId
    )


gotDeleteMealEntryResponse : Page.Model -> MealEntryId -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteMealEntryResponse model mealEntryId result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (Lens.modify Page.lenses.mealEntries (Dict.remove mealEntryId) model
                |> always
            )
    , Cmd.none
    )


gotFetchMealEntriesResponse : Page.Model -> Result Error (List MealEntry) -> ( Page.Model, Cmd Page.Msg )
gotFetchMealEntriesResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\mealEntries ->
                model
                    |> Page.lenses.mealEntries.set (mealEntries |> List.map (\mealEntry -> ( mealEntry.id, Left mealEntry )) |> Dict.fromList)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.mealEntries).set True
            )
    , Cmd.none
    )


gotFetchRecipesResponse : Page.Model -> Result Error (List Recipe) -> ( Page.Model, Cmd Page.Msg )
gotFetchRecipesResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\recipes ->
                model
                    |> Page.lenses.recipes.set (recipes |> List.map (\r -> ( r.id, r )) |> Dict.fromList)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.recipes).set True
            )
    , Cmd.none
    )


gotFetchMealResponse : Page.Model -> Result Error Meal -> ( Page.Model, Cmd Page.Msg )
gotFetchMealResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\meal ->
                model
                    |> Page.lenses.mealInfo.set (meal |> MealInfo.from |> Just)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.meal).set True
            )
    , Cmd.none
    )


selectRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
selectRecipe model recipeId =
    ( model
        |> Lens.modify Page.lenses.mealEntriesToAdd
            (Dict.update recipeId
                (always (MealEntryCreationClientInput.default model.mealId recipeId) >> Just)
            )
    , Cmd.none
    )


deselectRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
deselectRecipe model recipeId =
    ( model
        |> Lens.modify Page.lenses.mealEntriesToAdd (Dict.remove recipeId)
    , Cmd.none
    )


addRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
addRecipe model recipeId =
    ( model
    , Dict.get recipeId model.mealEntriesToAdd
        |> Maybe.map
            (MealEntryCreationClientInput.toCreation
                >> Requests.addMealEntry model.authorizedAccess
            )
        |> Maybe.withDefault Cmd.none
    )


gotAddMealEntryResponse : Page.Model -> Result Error MealEntry -> ( Page.Model, Cmd Page.Msg )
gotAddMealEntryResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\mealEntry ->
                model
                    |> Lens.modify Page.lenses.mealEntries
                        (Dict.update mealEntry.id (always mealEntry >> Left >> Just))
                    |> Lens.modify Page.lenses.mealEntriesToAdd (Dict.remove mealEntry.recipeId)
            )
    , Cmd.none
    )


updateAddRecipe : Page.Model -> MealEntryCreationClientInput -> ( Page.Model, Cmd Page.Msg )
updateAddRecipe model mealEntryCreationClientInput =
    ( model
        |> Lens.modify Page.lenses.mealEntriesToAdd
            (Dict.update mealEntryCreationClientInput.recipeId (always mealEntryCreationClientInput >> Just))
    , Cmd.none
    )


setRecipesSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setRecipesSearchString model string =
    ( PaginationSettings.setSearchStringAndReset
        { searchStringLens =
            Page.lenses.recipesSearchString
        , paginationSettingsLens =
            Page.lenses.pagination
                |> Compose.lensWithLens Pagination.lenses.recipes
        }
        model
        string
    , Cmd.none
    )


setEntriesSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setEntriesSearchString model string =
    ( PaginationSettings.setSearchStringAndReset
        { searchStringLens =
            Page.lenses.entriesSearchString
        , paginationSettingsLens =
            Page.lenses.pagination
                |> Compose.lensWithLens Pagination.lenses.mealEntries
        }
        model
        string
    , Cmd.none
    )


setPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setPagination model pagination =
    ( model |> Page.lenses.pagination.set pagination
    , Cmd.none
    )


mapMealEntryOrUpdateById : MealEntryId -> (Page.MealEntryOrUpdate -> Page.MealEntryOrUpdate) -> Page.Model -> Page.Model
mapMealEntryOrUpdateById mealEntryId =
    Page.lenses.mealEntries
        |> LensUtil.updateById mealEntryId


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
