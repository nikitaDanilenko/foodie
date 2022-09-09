module Pages.MealEntryEditor.Handler exposing (..)

import Api.Auxiliary exposing (JWT, MealEntryId, RecipeId)
import Api.Types.MealEntry exposing (MealEntry, decoderMealEntry)
import Api.Types.MealEntryCreation exposing (MealEntryCreation, encoderMealEntryCreation)
import Api.Types.MealEntryUpdate exposing (MealEntryUpdate, encoderMealEntryUpdate)
import Api.Types.Recipe exposing (Recipe, decoderRecipe)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Dict
import Either exposing (Either(..))
import Http exposing (Error)
import Json.Decode as Decode
import List.Extra
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Monocle.Optional as Optional
import Pages.MealEntryEditor.MealEntryCreationClientInput as MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntryEditor.MealEntryUpdateClientInput as MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Pages.MealEntryEditor.Page as Page exposing (FlagsWithJWT, Msg(..), RecipeMap)
import Url.Builder
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil as HttpUtil
import Util.LensUtil as LensUtil
import Util.ListUtil as ListUtil


updateMealEntry : Page.Model -> MealEntryUpdateClientInput -> ( Page.Model, Cmd msg )
updateMealEntry model mealEntryUpdateClientInput =
    ( model
        |> mapMealEntryOrUpdateById mealEntryUpdateClientInput.mealEntryId
            (Either.mapRight (Editing.updateLens.set mealEntryUpdateClientInput))
    , Cmd.none
    )


saveMealEntryEdit : Page.Model -> MealEntryId -> ( Page.Model, Cmd Msg )
saveMealEntryEdit model mealEntryId =
    ( model
    , model
        |> Page.lenses.mealEntries.get
        |> List.Extra.find (mealEntryIdIs mealEntryId)
        |> Maybe.andThen Either.rightToMaybe
        |> Maybe.Extra.unwrap Cmd.none
            (.update >> MealEntryUpdateClientInput.to >> saveMealEntryRequest model.flagsWithJWT)
    )


gotSaveMealEntryResponse : Page.Model -> Result Error MealEntry -> ( Page.Model, Cmd Msg )
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


enterEditMealEntry : Page.Model -> MealEntryId -> ( Page.Model, Cmd Msg )
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


exitEditMealEntryAt : Page.Model -> MealEntryId -> ( Page.Model, Cmd Msg )
exitEditMealEntryAt model mealEntryId =
    ( model
        |> mapMealEntryOrUpdateById mealEntryId (Either.andThen (.original >> Left))
    , Cmd.none
    )


deleteMealEntry : Page.Model -> MealEntryId -> ( Page.Model, Cmd Msg )
deleteMealEntry model mealEntryId =
    ( model
    , deleteMealEntryRequest model.flagsWithJWT mealEntryId
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


gotFetchMealEntriesResponse : Page.Model -> Result Error (List MealEntry) -> ( Page.Model, Cmd Msg )
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


selectRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd msg )
selectRecipe model recipeId =
    ( model
        |> Lens.modify Page.lenses.mealEntriesToAdd
            (ListUtil.insertBy
                { compareA = .recipeId >> recipeNameOrEmpty model.recipes
                , compareB = .recipeId >> recipeNameOrEmpty model.recipes
                , mapAB = identity
                }
                (MealEntryCreationClientInput.default model.flagsWithJWT.mealId recipeId)
            )
    , Cmd.none
    )


deselectRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Msg )
deselectRecipe model recipeId =
    ( model
        |> Lens.modify Page.lenses.mealEntriesToAdd (List.Extra.filterNot (\me -> me.recipeId == recipeId))
    , Cmd.none
    )


addRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Msg )
addRecipe model recipeId =
    ( model
    , List.Extra.find (\me -> me.recipeId == recipeId) model.mealEntriesToAdd
        |> Maybe.map
            (MealEntryCreationClientInput.toCreation
                >> AddMealEntryParams model.flagsWithJWT.configuration model.flagsWithJWT.jwt
                >> addMealEntryRequest
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
                            { compareA = .recipeId >> recipeNameOrEmpty model.recipes
                            , compareB = recipeIdOf >> recipeNameOrEmpty model.recipes
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


updateJWT : Page.Model -> JWT -> ( Page.Model, Cmd Msg )
updateJWT model jwt =
    ( Page.lenses.jwt.set jwt model
    , fetchRecipesRequest model.flagsWithJWT
    )


updateRecipes model string =
    let
        newModel =
            (Decode.list decoderRecipe
                |> Decode.decodeString
            )
                >> Either.fromResult
                >> Either.unwrap model
                    (List.map (\r -> ( r.id, r ))
                        >> Dict.fromList
                        >> flip Page.lenses.recipes.set model
                    )
    in
    ( newModel string
    , Cmd.none
    )


setRecipesSearchString : Page.Model -> String -> ( Page.Model, Cmd msg )
setRecipesSearchString model string =
    ( model |> Page.lenses.recipeSearchString.set string
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


recipeNameOrEmpty : RecipeMap -> RecipeId -> String
recipeNameOrEmpty recipeMap =
    flip Dict.get recipeMap >> Maybe.Extra.unwrap "" .name


fetchRecipesRequest : FlagsWithJWT -> Cmd Msg
fetchRecipesRequest flags =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "meal", "all" ] []
        , expect = HttpUtil.expectJson GotFetchRecipesResponse (Decode.list decoderRecipe)
        }


saveMealEntryRequest : FlagsWithJWT -> MealEntryUpdate -> Cmd Msg
saveMealEntryRequest flags mealEntryUpdate =
    HttpUtil.patchJsonWithJWT
        flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "meal", "update-meal-entry" ] []
        , body = encoderMealEntryUpdate mealEntryUpdate
        , expect = HttpUtil.expectJson GotSaveMealEntryResponse decoderMealEntry
        }


deleteMealEntryRequest : FlagsWithJWT -> MealEntryId -> Cmd Msg
deleteMealEntryRequest fs mealEntryId =
    HttpUtil.deleteWithJWT fs.jwt
        { url = Url.Builder.relative [ fs.configuration.backendURL, "meal", "delete-meal-entry", mealEntryId ] []
        , expect = HttpUtil.expectWhatever (GotDeleteMealEntryResponse mealEntryId)
        }


type alias AddMealEntryParams =
    { configuration : Configuration
    , jwt : JWT
    , mealEntryCreation : MealEntryCreation
    }


addMealEntryRequest : AddMealEntryParams -> Cmd Msg
addMealEntryRequest ps =
    HttpUtil.patchJsonWithJWT ps.jwt
        { url = Url.Builder.relative [ ps.configuration.backendURL, "meal", "add-meal-entry" ] []
        , body = encoderMealEntryCreation ps.mealEntryCreation
        , expect = HttpUtil.expectJson GotAddMealEntryResponse decoderMealEntry
        }
