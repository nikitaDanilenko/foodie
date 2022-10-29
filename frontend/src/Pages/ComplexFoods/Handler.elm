module Pages.ComplexFoods.Handler exposing (init, update)

import Api.Auxiliary exposing (ComplexFoodId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexFoodUnit as ComplexFoodUnit
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Dict
import Either exposing (Either(..))
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Monocle.Optional as Optional
import Pages.ComplexFoods.ComplexFoodClientInput as ComplexFoodClientInput exposing (ComplexFoodClientInput)
import Pages.ComplexFoods.Page as Page
import Pages.ComplexFoods.Pagination as Pagination
import Pages.ComplexFoods.Requests as Requests
import Pages.ComplexFoods.Status as Status
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.ValidatedInput as ValidatedInput
import Util.Editing as Editing
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization as Initialization
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , recipes = Dict.empty
      , complexFoods = Dict.empty
      , complexFoodsToCreate = Dict.empty
      , recipesSearchString = ""
      , initialization = Initialization.Loading Status.initial
      , pagination = Pagination.initial
      }
    , initialFetch flags.authorizedAccess
    )


initialFetch : AuthorizedAccess -> Cmd Page.Msg
initialFetch authorizedAccess =
    Cmd.batch
        [ Requests.fetchRecipes authorizedAccess
        , Requests.fetchComplexFoods authorizedAccess
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.UpdateComplexFoodCreation createComplexFoodsMap ->
            updateComplexFoodCreation model createComplexFoodsMap

        Page.CreateComplexFood recipeId ->
            createComplexFood model recipeId

        Page.GotCreateComplexFoodResponse result ->
            gotCreateComplexFoodResponse model result

        Page.UpdateComplexFood complexFoodClientInput ->
            updateComplexFood model complexFoodClientInput

        Page.SaveComplexFoodEdit complexFoodClientInput ->
            saveComplexFoodEdit model complexFoodClientInput

        Page.GotSaveComplexFoodResponse result ->
            gotSaveComplexFoodResponse model result

        Page.EnterEditComplexFood complexFoodId ->
            enterEditComplexFood model complexFoodId

        Page.ExitEditComplexFood complexFoodId ->
            exitEditComplexFood model complexFoodId

        Page.DeleteComplexFood complexFoodId ->
            deleteComplexFood model complexFoodId

        Page.GotDeleteComplexFoodResponse complexFoodId result ->
            gotDeleteComplexFoodResponse model complexFoodId result

        Page.GotFetchRecipesResponse result ->
            gotFetchRecipesResponse model result

        Page.GotFetchComplexFoodsResponse result ->
            gotFetchComplexFoodsResponse model result

        Page.SelectRecipe recipe ->
            selectRecipe model recipe

        Page.DeselectRecipe recipeId ->
            deselectRecipe model recipeId

        Page.SetRecipesSearchString string ->
            setRecipesSearchString model string

        Page.SetPagination pagination ->
            setPagination model pagination


updateComplexFoodCreation : Page.Model -> ComplexFoodClientInput -> ( Page.Model, Cmd Page.Msg )
updateComplexFoodCreation model complexFoodClientInput =
    ( model
        |> Lens.modify Page.lenses.complexFoodsToCreate
            (Dict.update complexFoodClientInput.recipeId (always complexFoodClientInput >> Just))
    , Cmd.none
    )


createComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.Msg )
createComplexFood model recipeId =
    ( model
    , model
        |> (Page.lenses.complexFoodsToCreate
                |> Compose.lensWithOptional (LensUtil.dictByKey recipeId)
           ).getOption
        |> Maybe.Extra.unwrap Cmd.none
            (ComplexFoodClientInput.to
                >> Requests.createComplexFood model.authorizedAccess
            )
    )


gotCreateComplexFoodResponse : Page.Model -> Result Error ComplexFood -> ( Page.Model, Cmd Page.Msg )
gotCreateComplexFoodResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\complexFood ->
                model
                    |> Lens.modify Page.lenses.complexFoods
                        (Dict.insert complexFood.recipeId (Left complexFood))
                    |> Lens.modify Page.lenses.complexFoodsToCreate
                        (Dict.remove complexFood.recipeId)
            )
    , Cmd.none
    )


updateComplexFood : Page.Model -> ComplexFoodClientInput -> ( Page.Model, Cmd Page.Msg )
updateComplexFood model complexFoodClientInput =
    ( model
        |> mapComplexFoodOrUpdateByRecipeId complexFoodClientInput.recipeId
            (Either.mapRight (Editing.lenses.update.set complexFoodClientInput))
    , Cmd.none
    )


saveComplexFoodEdit : Page.Model -> ComplexFoodClientInput -> ( Page.Model, Cmd Page.Msg )
saveComplexFoodEdit model complexFoodClientInput =
    ( model
    , complexFoodClientInput
        |> ComplexFoodClientInput.to
        |> Requests.updateComplexFood model.authorizedAccess
    )


gotSaveComplexFoodResponse : Page.Model -> Result Error ComplexFood -> ( Page.Model, Cmd Page.Msg )
gotSaveComplexFoodResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\complexFood ->
                model
                    |> mapComplexFoodOrUpdateByRecipeId complexFood.recipeId
                        (Either.andThen (always (Left complexFood)))
                    |> Lens.modify Page.lenses.complexFoodsToCreate (Dict.remove complexFood.recipeId)
                    |> Lens.modify Page.lenses.complexFoods (Dict.update complexFood.recipeId (always complexFood >> Left >> Just))
            )
    , Cmd.none
    )


enterEditComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.Msg )
enterEditComplexFood model complexFoodId =
    ( model
        |> mapComplexFoodOrUpdateByRecipeId complexFoodId
            (Either.unpack (\complexFood -> { original = complexFood, update = ComplexFoodClientInput.from complexFood }) identity >> Right)
    , Cmd.none
    )


exitEditComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.Msg )
exitEditComplexFood model complexFoodId =
    ( model |> mapComplexFoodOrUpdateByRecipeId complexFoodId (Either.andThen (.original >> Left))
    , Cmd.none
    )


deleteComplexFood : Page.Model -> ComplexFoodId -> ( Page.Model, Cmd Page.Msg )
deleteComplexFood model complexFoodId =
    ( model
    , Requests.deleteComplexFood model.authorizedAccess complexFoodId
    )


gotDeleteComplexFoodResponse : Page.Model -> ComplexFoodId -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteComplexFoodResponse model complexFoodId result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (always
                (model
                    |> Lens.modify Page.lenses.complexFoods (Dict.remove complexFoodId)
                )
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


gotFetchComplexFoodsResponse : Page.Model -> Result Error (List ComplexFood) -> ( Page.Model, Cmd Page.Msg )
gotFetchComplexFoodsResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\complexFoods ->
                model
                    |> Page.lenses.complexFoods.set (complexFoods |> List.map (\r -> ( r.recipeId, Left r )) |> Dict.fromList)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.complexFoods).set True
            )
    , Cmd.none
    )


selectRecipe : Page.Model -> Recipe -> ( Page.Model, Cmd Page.Msg )
selectRecipe model recipe =
    ( model
        |> Lens.modify Page.lenses.complexFoodsToCreate
            (Dict.update recipe.id (always { recipeId = recipe.id, amount = ValidatedInput.positive, unit = ComplexFoodUnit.G } >> Just))
    , Cmd.none
    )


deselectRecipe : Page.Model -> RecipeId -> ( Page.Model, Cmd Page.Msg )
deselectRecipe model recipeId =
    ( model
        |> Lens.modify Page.lenses.complexFoodsToCreate (Dict.remove recipeId)
    , Cmd.none
    )


setRecipesSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setRecipesSearchString model string =
    ( PaginationSettings.setSearchStringAndReset
        { searchStringLens = Page.lenses.recipesSearchString
        , paginationSettingsLens =
            Page.lenses.pagination
                |> Compose.lensWithLens Pagination.lenses.recipes
        }
        model
        string
    , Cmd.none
    )


setPagination : Page.Model -> Pagination.Pagination -> ( Page.Model, Cmd Page.Msg )
setPagination model pagination =
    ( model
        |> Page.lenses.pagination.set pagination
    , Cmd.none
    )


mapComplexFoodOrUpdateByRecipeId : ComplexFoodId -> (Page.ComplexFoodOrUpdate -> Page.ComplexFoodOrUpdate) -> Page.Model -> Page.Model
mapComplexFoodOrUpdateByRecipeId recipeId =
    Page.lenses.complexFoods
        |> Compose.lensWithOptional (LensUtil.dictByKey recipeId)
        |> Optional.modify


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
