module Pages.Recipes.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT, RecipeId)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Either exposing (Either(..))
import Http exposing (Error)
import List.Extra
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Monocle.Optional as Optional
import Pages.Recipes.Page as Page exposing (RecipeOrUpdate)
import Pages.Recipes.RecipeUpdateClientInput as RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Recipes.Requests as Requests
import Ports exposing (doFetchToken)
import Util.Editing as Editing exposing (Editing)
import Util.LensUtil as LensUtil
import Util.ListUtil as ListUtil


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
                model
                    |> Lens.modify Page.lenses.recipes
                        (ListUtil.insertBy
                            { compareA = .name
                            , compareB = recipeNameOf
                            , mapAB = Left
                            }
                            recipe
                        )
            )
    , Cmd.none
    )


recipeNameOf : Page.RecipeOrUpdate -> String
recipeNameOf =
    Either.unpack
        .name
        (.original >> .name)


updateRecipe : Page.Model -> RecipeUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
updateRecipe model recipeUpdate =
    ( model
        |> mapRecipeOrUpdateById recipeUpdate.id
            (Either.mapRight (Editing.updateLens.set recipeUpdate))
    , Cmd.none
    )


saveRecipeEdit : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
saveRecipeEdit model recipeId =
    ( model
    , model
        |> Page.lenses.recipes.get
        |> List.Extra.find (recipeIdIs recipeId)
        |> Maybe.andThen Either.rightToMaybe
        |> Maybe.Extra.unwrap
            Cmd.none
            (.update
                >> RecipeUpdateClientInput.to
                >> Requests.saveRecipe model.flagsWithJWT
            )
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


mapRecipeOrUpdateById : RecipeId -> (Page.RecipeOrUpdate -> Page.RecipeOrUpdate) -> Page.Model -> Page.Model
mapRecipeOrUpdateById recipeId =
    Page.lenses.recipes
        |> Compose.lensWithOptional (recipeId |> recipeIdIs |> LensUtil.firstSuch)
        |> Optional.modify


recipeIdIs : RecipeId -> Page.RecipeOrUpdate -> Bool
recipeIdIs =
    Editing.is .id
