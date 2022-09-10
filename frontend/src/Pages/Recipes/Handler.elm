module Pages.Recipes.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT, RecipeId)
import Api.Types.Recipe exposing (Recipe)
import Api.Types.RecipeUpdate exposing (RecipeUpdate)
import Basics.Extra exposing (flip)
import Either exposing (Either(..))
import Http exposing (Error)
import List.Extra
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Monocle.Optional as Optional
import Pages.Recipes.Page as Page exposing (RecipeOrUpdate)
import Pages.Recipes.Requests as Requests
import Ports exposing (doFetchToken)
import Util.Editing as Editing exposing (Editing)
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    let
        ( jwt, cmd ) =
            flags.jwt
                |> Maybe.Extra.unwrap
                    ( "", doFetchToken () )
                    (\token ->
                        ( token
                        , Requests.fetchRecipes
                            { configuration = flags.configuration
                            , jwt = token
                            }
                        )
                    )
    in
    ( { flagsWithJWT =
            { configuration = flags.configuration
            , jwt = jwt
            }
      , recipes = []
      }
    , cmd
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.CreateRecipe ->
            createRecipe model

        Page.GotCreateRecipeResponse dataOrError ->
            gotCreateRecipeResponse model dataOrError

        Page.UpdateRecipe recipeUpdate ->
            updateRecipe model recipeUpdate

        Page.SaveRecipeEdit recipeId ->
            saveRecipeEdit model recipeId

        Page.GotSaveRecipeResponse dataOrError ->
            gotSaveRecipeResponse model dataOrError

        Page.EnterEditRecipe recipeId ->
            enterEditRecipe model recipeId

        Page.ExitEditRecipeAt recipeId ->
            exitEditRecipeAt model recipeId

        Page.DeleteRecipe recipeId ->
            deleteRecipe model recipeId

        Page.GotDeleteRecipeResponse deletedId dataOrError ->
            gotDeleteRecipeResponse model deletedId dataOrError

        Page.GotFetchRecipesResponse dataOrError ->
            gotFetchRecipesResponse model dataOrError

        Page.UpdateJWT jwt ->
            updateJWT model jwt


createRecipe : Page.Model -> ( Page.Model, Cmd Page.Msg )
createRecipe model =
    ( model, Requests.createRecipe model.flagsWithJWT )


gotCreateRecipeResponse : Page.Model -> Result Error Recipe -> ( Page.Model, Cmd Page.Msg )
gotCreateRecipeResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unwrap model
            (\recipe ->
                Lens.modify Page.lenses.recipes
                    (\ts ->
                        Right
                            { original = recipe
                            , update = recipeUpdateFromRecipe recipe
                            }
                            :: ts
                    )
                    model
            )
    , Cmd.none
    )


updateRecipe : Page.Model -> RecipeUpdate -> ( Page.Model, Cmd Page.Msg )
updateRecipe model recipeUpdate =
    ( model
        |> mapRecipeOrUpdateById recipeUpdate.id
            (Either.mapRight (Editing.updateLens.set recipeUpdate))
    , Cmd.none
    )


saveRecipeEdit : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
saveRecipeEdit model recipeId =
    ( model
    , Maybe.Extra.unwrap
        Cmd.none
        (Either.unwrap Cmd.none
            (.update
                >> Requests.saveRecipe model.flagsWithJWT
            )
        )
        (List.Extra.find (recipeIdIs recipeId) model.recipes)
    )


gotSaveRecipeResponse : Page.Model -> Result Error Recipe -> ( Page.Model, Cmd Page.Msg )
gotSaveRecipeResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unwrap model
            (\recipe ->
                model
                    |> mapRecipeOrUpdateById recipe.id
                        (Either.andThenRight (always (Left recipe)))
            )
    , Cmd.none
    )


enterEditRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
enterEditRecipe model recipeId =
    ( model
        |> mapRecipeOrUpdateById recipeId
            (Either.unpack (\recipe -> { original = recipe, update = recipeUpdateFromRecipe recipe }) identity >> Right)
    , Cmd.none
    )


exitEditRecipeAt : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
exitEditRecipeAt model recipeId =
    ( model |> mapRecipeOrUpdateById recipeId (Either.andThen (.original >> Left))
    , Cmd.none
    )


deleteRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
deleteRecipe model recipeId =
    ( model
    , Requests.deleteRecipe model.flagsWithJWT recipeId
    )


gotDeleteRecipeResponse : Page.Model -> RecipeId -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteRecipeResponse model deletedId dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unwrap model
            (always
                (model
                    |> Lens.modify Page.lenses.recipes
                        (List.Extra.filterNot (recipeIdIs deletedId))
                )
            )
    , Cmd.none
    )


gotFetchRecipesResponse : Page.Model -> Result Error (List Recipe) -> ( Page.Model, Cmd Page.Msg )
gotFetchRecipesResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unwrap model (List.map Left >> flip Page.lenses.recipes.set model)
    , Cmd.none
    )


updateJWT : Page.Model -> JWT -> ( Page.Model, Cmd Page.Msg )
updateJWT model jwt =
    let
        newModel =
            Page.lenses.jwt.set jwt model
    in
    ( newModel
    , Requests.fetchRecipes newModel.flagsWithJWT
    )


mapRecipeOrUpdateById : RecipeId -> (RecipeOrUpdate -> RecipeOrUpdate) -> Page.Model -> Page.Model
mapRecipeOrUpdateById recipeId =
    Page.lenses.recipes
        |> Compose.lensWithOptional (recipeId |> recipeIdIs |> LensUtil.firstSuch)
        |> Optional.modify


recipeIdIs : RecipeId -> Either Recipe (Editing Recipe RecipeUpdate) -> Bool
recipeIdIs =
    Editing.is .id


recipeUpdateFromRecipe : Recipe -> RecipeUpdate
recipeUpdateFromRecipe r =
    { id = r.id
    , name = r.name
    , description = r.description
    }
