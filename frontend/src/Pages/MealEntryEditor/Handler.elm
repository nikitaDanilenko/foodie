module Pages.MealEntryEditor.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT, MealEntryId, RecipeId)
import Api.Types.Meal exposing (Meal)
import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Dict
import Either exposing (Either(..))
import Http exposing (Error)
import List.Extra
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Monocle.Optional as Optional
import Pages.MealEntryEditor.MealEntryCreationClientInput as MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntryEditor.MealEntryUpdateClientInput as MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Pages.MealEntryEditor.MealInfo as MealInfo
import Pages.MealEntryEditor.Page as Page exposing (Msg(..))
import Pages.MealEntryEditor.Requests as Requests
import Ports
import Util.Editing as Editing exposing (Editing)
import Util.LensUtil as LensUtil
import Util.ListUtil as ListUtil


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
                            , mealId = flags.mealId
                            }
                        )
                    )
    in
    ( { flagsWithJWT =
            { configuration = flags.configuration
            , jwt = jwt
            , mealId = flags.mealId
            }
      , mealInfo = Nothing
      , mealEntries = []
      , recipes = Dict.empty
      , recipesSearchString = ""
      , mealEntriesToAdd = []
      }
    , cmd
    )


initialFetch : Page.FlagsWithJWT -> Cmd Page.Msg
initialFetch flags =
    Cmd.batch
        [ Requests.fetchMeal flags
        , Requests.fetchRecipes
            { configuration = flags.configuration
            , jwt = flags.jwt
            }
        , Requests.fetchMealEntries flags
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        UpdateMealEntry mealEntryUpdateClientInput ->
            updateMealEntry model mealEntryUpdateClientInput

        SaveMealEntryEdit mealEntryId ->
            saveMealEntryEdit model mealEntryId

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


saveMealEntryEdit : Page.Model -> MealEntryId -> ( Page.Model, Cmd Page.Msg )
saveMealEntryEdit model mealEntryId =
    ( model
    , model
        |> Page.lenses.mealEntries.get
        |> List.Extra.find (mealEntryIdIs mealEntryId)
        |> Maybe.andThen Either.rightToMaybe
        |> Maybe.Extra.unwrap Cmd.none
            (.update >> MealEntryUpdateClientInput.to >> Requests.saveMealEntry model.flagsWithJWT)
    )


gotSaveMealEntryResponse : Page.Model -> Result Error MealEntry -> ( Page.Model, Cmd Page.Msg )
gotSaveMealEntryResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unwrap model
            (\mealEntry ->
                mapMealEntryOrUpdateById mealEntry.id
                    (Either.andThenRight (always (Left mealEntry)))
                    model
            )
    , Cmd.none
    )


enterEditMealEntry : Page.Model -> MealEntryId -> ( Page.Model, Cmd Page.Msg )
enterEditMealEntry model mealEntryId =
    ( model
        |> mapMealEntryOrUpdateById mealEntryId
            (Either.andThenLeft
                (\me ->
                    Right
                        { original = me
                        , update = MealEntryUpdateClientInput.from me
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
        |> Either.unwrap model
            (Lens.modify Page.lenses.mealEntries (List.Extra.filterNot (mealEntryIdIs mealEntryId)) model
                |> always
            )
    , Cmd.none
    )


gotFetchMealEntriesResponse : Page.Model -> Result Error (List MealEntry) -> ( Page.Model, Cmd Page.Msg )
gotFetchMealEntriesResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unwrap model
            (List.map Left >> flip Page.lenses.mealEntries.set model)
    , Cmd.none
    )


gotFetchRecipesResponse : Page.Model -> Result Error (List Recipe) -> ( Page.Model, Cmd msg )
gotFetchRecipesResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unwrap model
            (List.map (\r -> ( r.id, r ))
                >> Dict.fromList
                >> flip Page.lenses.recipes.set model
            )
    , Cmd.none
    )


gotFetchMealResponse : Page.Model -> Result Error Meal -> ( Page.Model, Cmd Page.Msg )
gotFetchMealResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unwrap model
            (MealInfo.from
                >> Just
                >> flip Page.lenses.mealInfo.set model
            )
    , Cmd.none
    )


selectRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd msg )
selectRecipe model recipeId =
    ( model
        |> Lens.modify Page.lenses.mealEntriesToAdd
            (ListUtil.insertBy
                { compareA = .recipeId >> Page.recipeNameOrEmpty model.recipes
                , compareB = .recipeId >> Page.recipeNameOrEmpty model.recipes
                , mapAB = identity
                }
                (MealEntryCreationClientInput.default model.flagsWithJWT.mealId recipeId)
            )
    , Cmd.none
    )


deselectRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
deselectRecipe model recipeId =
    ( model
        |> Lens.modify Page.lenses.mealEntriesToAdd (List.Extra.filterNot (\me -> me.recipeId == recipeId))
    , Cmd.none
    )


addRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
addRecipe model recipeId =
    ( model
    , List.Extra.find (\me -> me.recipeId == recipeId) model.mealEntriesToAdd
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
        |> Either.map
            (\mealEntry ->
                model
                    |> Lens.modify Page.lenses.mealEntries
                        (ListUtil.insertBy
                            { compareA = .recipeId >> Page.recipeNameOrEmpty model.recipes
                            , compareB = recipeIdOf >> Page.recipeNameOrEmpty model.recipes
                            , mapAB = Left
                            }
                            mealEntry
                        )
                    |> Lens.modify Page.lenses.mealEntriesToAdd (List.Extra.filterNot (\me -> me.recipeId == mealEntry.recipeId))
            )
        |> Either.withDefault model
    , Cmd.none
    )


updateAddRecipe : Page.Model -> MealEntryCreationClientInput -> ( Page.Model, Cmd msg )
updateAddRecipe model mealEntryCreationClientInput =
    ( model
        |> Lens.modify Page.lenses.mealEntriesToAdd
            (List.Extra.setIf
                (\me -> me.recipeId == mealEntryCreationClientInput.recipeId)
                mealEntryCreationClientInput
            )
    , Cmd.none
    )


updateJWT : Page.Model -> JWT -> ( Page.Model, Cmd Page.Msg )
updateJWT model jwt =
    let
        newModel =
            Page.lenses.jwt.set jwt model
    in
    ( newModel
    , initialFetch newModel.flagsWithJWT
    )


setRecipesSearchString : Page.Model -> String -> ( Page.Model, Cmd msg )
setRecipesSearchString model string =
    ( model |> Page.lenses.recipesSearchString.set string
    , Cmd.none
    )


mapMealEntryOrUpdateById : MealEntryId -> (Page.MealEntryOrUpdate -> Page.MealEntryOrUpdate) -> Page.Model -> Page.Model
mapMealEntryOrUpdateById ingredientId =
    Page.lenses.mealEntries
        |> Compose.lensWithOptional (ingredientId |> Editing.is .id |> LensUtil.firstSuch)
        |> Optional.modify


mealEntryIdIs : MealEntryId -> Page.MealEntryOrUpdate -> Bool
mealEntryIdIs mealEntryId =
    Either.unpack
        (\i -> i.id == mealEntryId)
        (\e -> e.original.id == mealEntryId)


recipeIdOf : Either MealEntry (Editing MealEntry MealEntryUpdateClientInput) -> RecipeId
recipeIdOf =
    Either.unpack
        .recipeId
        (.original >> .recipeId)
