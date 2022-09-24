module Pages.MealEntries.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT, MealEntryId, MealId, RecipeId)
import Api.Types.Meal exposing (Meal)
import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Dict
import Either exposing (Either(..))
import Http exposing (Error)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Monocle.Optional as Optional
import Pages.MealEntries.MealEntryCreationClientInput as MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntries.MealEntryUpdateClientInput as MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Pages.MealEntries.MealInfo as MealInfo
import Pages.MealEntries.Page as Page exposing (Msg(..))
import Pages.MealEntries.Requests as Requests
import Pages.MealEntries.Status as Status
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Ports
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil as HttpUtil
import Util.Initialization exposing (Initialization(..))
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    let
        ( jwt, cmd ) =
            flags.jwt
                |> Maybe.Extra.unwrap ( "", Ports.doFetchToken () )
                    (\token ->
                        ( token
                        , initialFetch
                            { configuration = flags.configuration
                            , jwt = token
                            }
                            flags.mealId
                        )
                    )
    in
    ( { flagsWithJWT =
            { configuration = flags.configuration
            , jwt = jwt
            }
      , mealId = flags.mealId
      , mealInfo = Nothing
      , mealEntries = Dict.empty
      , recipes = Dict.empty
      , recipesSearchString = ""
      , mealEntriesToAdd = Dict.empty
      , initialization = Loading (Status.initial |> Status.lenses.jwt.set (jwt |> String.isEmpty |> not))
      }
    , cmd
    )


initialFetch : FlagsWithJWT -> MealId -> Cmd Page.Msg
initialFetch flags mealId =
    Cmd.batch
        [ Requests.fetchMeal flags mealId
        , Requests.fetchRecipes flags
        , Requests.fetchMealEntries flags mealId
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

        UpdateJWT jwt ->
            updateJWT model jwt

        SetRecipesSearchString string ->
            setRecipesSearchString model string


updateMealEntry : Page.Model -> MealEntryUpdateClientInput -> ( Page.Model, Cmd msg )
updateMealEntry model mealEntryUpdateClientInput =
    ( model
        |> mapMealEntryOrUpdateById mealEntryUpdateClientInput.mealEntryId
            (Either.mapRight (Editing.updateLens.set mealEntryUpdateClientInput))
    , Cmd.none
    )


saveMealEntryEdit : Page.Model -> MealEntryUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
saveMealEntryEdit model mealEntryUpdateClientInput =
    ( model
    , mealEntryUpdateClientInput
        |> MealEntryUpdateClientInput.to
        |> Requests.saveMealEntry model.flagsWithJWT
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
    , Requests.deleteMealEntry model.flagsWithJWT mealEntryId
    )


gotDeleteMealEntryResponse : Page.Model -> MealEntryId -> Result Error () -> ( Page.Model, Cmd msg )
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


gotFetchRecipesResponse : Page.Model -> Result Error (List Recipe) -> ( Page.Model, Cmd msg )
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


selectRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd msg )
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
                >> Requests.AddMealEntryParams model.flagsWithJWT.configuration model.flagsWithJWT.jwt
                >> Requests.addMealEntry
            )
        |> Maybe.withDefault Cmd.none
    )


gotAddMealEntryResponse : Page.Model -> Result Error MealEntry -> ( Page.Model, Cmd msg )
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


updateAddRecipe : Page.Model -> MealEntryCreationClientInput -> ( Page.Model, Cmd msg )
updateAddRecipe model mealEntryCreationClientInput =
    ( model
        |> Lens.modify Page.lenses.mealEntriesToAdd
            (Dict.update mealEntryCreationClientInput.recipeId (always mealEntryCreationClientInput >> Just))
    , Cmd.none
    )


updateJWT : Page.Model -> JWT -> ( Page.Model, Cmd Page.Msg )
updateJWT model jwt =
    let
        newModel =
            model
                |> Page.lenses.jwt.set jwt
                |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.jwt).set True
    in
    ( newModel
    , initialFetch newModel.flagsWithJWT newModel.mealId
    )


setRecipesSearchString : Page.Model -> String -> ( Page.Model, Cmd msg )
setRecipesSearchString model string =
    ( model |> Page.lenses.recipesSearchString.set string
    , Cmd.none
    )


mapMealEntryOrUpdateById : MealEntryId -> (Page.MealEntryOrUpdate -> Page.MealEntryOrUpdate) -> Page.Model -> Page.Model
mapMealEntryOrUpdateById mealEntryId =
    Page.lenses.mealEntries
        |> Compose.lensWithOptional (LensUtil.dictByKey mealEntryId)
        |> Optional.modify


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
