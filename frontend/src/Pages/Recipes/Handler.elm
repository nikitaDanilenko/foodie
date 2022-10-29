module Pages.Recipes.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT, RecipeId)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Dict
import Either exposing (Either(..))
import Maybe.Extra
import Monocle.Lens as Lens
import Monocle.Optional
import Pages.Recipes.Page as Page exposing (RecipeOrUpdate)
import Pages.Recipes.Pagination as Pagination exposing (Pagination)
import Pages.Recipes.RecipeCreationClientInput as RecipeCreationClientInput exposing (RecipeCreationClientInput)
import Pages.Recipes.RecipeUpdateClientInput as RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Recipes.Requests as Requests
import Pages.Recipes.Status as Status
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization as Initialization exposing (Initialization(..))
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , recipes = Dict.empty
      , recipeToAdd = Nothing
      , initialization = Initialization.Loading Status.initial
      , pagination = Pagination.initial
      }
    , Requests.fetchRecipes flags.authorizedAccess
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.UpdateRecipeCreation recipeCreationClientInput ->
            updateRecipeCreation model recipeCreationClientInput

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

        Page.SetPagination pagination ->
            setPagination model pagination


updateRecipeCreation : Page.Model -> Maybe RecipeCreationClientInput -> ( Page.Model, Cmd Page.Msg )
updateRecipeCreation model recipeToAdd =
    ( model
        |> Page.lenses.recipeToAdd.set recipeToAdd
    , Cmd.none
    )


createRecipe : Page.Model -> ( Page.Model, Cmd Page.Msg )
createRecipe model =
    ( model
    , model.recipeToAdd
        |> Maybe.Extra.unwrap Cmd.none (RecipeCreationClientInput.toCreation >> Requests.createRecipe model.authorizedAccess)
    )


gotCreateRecipeResponse : Page.Model -> Result Error Recipe -> ( Page.Model, Cmd Page.Msg )
gotCreateRecipeResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\recipe ->
                model
                    |> Lens.modify Page.lenses.recipes
                        (Dict.insert recipe.id (Left recipe))
                    |> Page.lenses.recipeToAdd.set Nothing
            )
    , Cmd.none
    )


updateRecipe : Page.Model -> RecipeUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
updateRecipe model recipeUpdate =
    ( model
        |> mapRecipeOrUpdateById recipeUpdate.id
            (Either.mapRight (Editing.lenses.update.set recipeUpdate))
    , Cmd.none
    )


saveRecipeEdit : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
saveRecipeEdit model recipeId =
    ( model
    , model
        |> Page.lenses.recipes.get
        |> Dict.get recipeId
        |> Maybe.andThen Either.rightToMaybe
        |> Maybe.Extra.unwrap
            Cmd.none
            (.update
                >> RecipeUpdateClientInput.to
                >> Requests.saveRecipe model.authorizedAccess
            )
    )


gotSaveRecipeResponse : Page.Model -> Result Error Recipe -> ( Page.Model, Cmd Page.Msg )
gotSaveRecipeResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
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
            (Either.unpack (\recipe -> { original = recipe, update = RecipeUpdateClientInput.from recipe }) identity >> Right)
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
    , Requests.deleteRecipe model.authorizedAccess recipeId
    )


gotDeleteRecipeResponse : Page.Model -> RecipeId -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteRecipeResponse model deletedId dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (always
                (model
                    |> Lens.modify Page.lenses.recipes
                        (Dict.remove deletedId)
                )
            )
    , Cmd.none
    )


gotFetchRecipesResponse : Page.Model -> Result Error (List Recipe) -> ( Page.Model, Cmd Page.Msg )
gotFetchRecipesResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\recipes ->
                model
                    |> Page.lenses.recipes.set (recipes |> List.map (\r -> ( r.id, Left r )) |> Dict.fromList)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.recipes).set True
            )
    , Cmd.none
    )


setPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setPagination model pagination =
    ( model |> Page.lenses.pagination.set pagination
    , Cmd.none
    )


mapRecipeOrUpdateById : RecipeId -> (Page.RecipeOrUpdate -> Page.RecipeOrUpdate) -> Page.Model -> Page.Model
mapRecipeOrUpdateById recipeId =
    Page.lenses.recipes
        |> LensUtil.updateById recipeId


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
