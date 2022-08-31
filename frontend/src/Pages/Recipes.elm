module Pages.Recipes exposing (Flags, Model, Msg, init, update, updateToken, view)

import Api.Auxiliary exposing (RecipeId)
import Api.Lenses.RecipeUpdateLens as RecipeUpdateLens
import Api.Types.Recipe exposing (Recipe, decoderRecipe)
import Api.Types.RecipeUpdate exposing (RecipeUpdate)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Either exposing (Either)
import Html exposing (Html, button, div, input, label, td, text, thead, tr)
import Html.Attributes exposing (class, id, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Http exposing (Error)
import Json.Decode as Decode
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.Util.Links as Links
import Ports exposing (doFetchToken)
import Url.Builder as UrlBuilder
import Util.Editing exposing (Editing)
import Util.HttpUtil as HttpUtil


type alias Model =
    { configuration : Configuration
    , token : String
    , recipes : List (Either Recipe (Editing Recipe RecipeUpdate))
    }


token : Lens Model String
token =
    Lens .token (\b a -> { a | token = b })


type Msg
    = CreateRecipe
    | GotCreateRecipeResponse (Result Error Recipe)
    | UpdateRecipe RecipeId RecipeUpdate
    | SaveRecipeEdit RecipeId
    | GotSaveRecipeResponse (Result Error Recipe)
    | EnterEditRecipe RecipeId
    | ExitEditRecipeAt RecipeId
    | DeleteRecipe RecipeId
    | GotFetchRecipesResponse (Result Error (List Recipe))
    | UpdateToken String


updateToken : String -> Msg
updateToken =
    UpdateToken


type alias Flags =
    { configuration : Configuration
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { configuration = flags.configuration
      , token = ""
      , recipes = []
      }
    , doFetchToken ()
    )


view : Model -> Html Msg
view model =
    let
        viewEditRecipes =
            List.map
                (Either.unpack
                    (editOrDeleteRecipeLine model.configuration model.token)
                    (\e -> e.update |> editRecipeLine e.original.id)
                )
    in
    div [ id "addRecipeView" ]
        (div [ id "addRecipe" ] [ button [ class "button", onClick CreateRecipe ] [ text "New recipe" ] ]
            :: thead []
                [ tr []
                    [ td [] [ label [] [ text "Name" ] ]
                    , td [] [ label [] [ text "Description" ] ]
                    ]
                ]
            :: viewEditRecipes model.recipes
        )


editOrDeleteRecipeLine : Configuration -> String -> Recipe -> Html Msg
editOrDeleteRecipeLine configuration t recipe =
    tr [ id "editingRecipe" ]
        [ td [] [ label [] [ text recipe.name ] ]
        , td [] [ label [] [ recipe.description |> Maybe.withDefault "" |> text ] ]
        , td [] [ button [ class "button", onClick (EnterEditRecipe recipe.id) ] [ text "Edit" ] ]
        , td []
            [ Links.linkButton
                { url =
                    UrlBuilder.relative
                        [ configuration.mainPageURL
                        , "#"
                        , "recipe"
                        , recipe.id
                        ]
                        []
                , attributes = [ class "button" ]
                , children = [ text "Edit" ]
                , isDisabled = False
                }
            ]
        , td [] [ button [ class "button", onClick (DeleteRecipe recipe.id) ] [ text "Delete" ] ]
        ]


editRecipeLine : RecipeId -> RecipeUpdate -> Html Msg
editRecipeLine recipeId recipeUpdateClientInput =
    let
        createOnEnter =
            onEnter (SaveRecipeEdit recipeId)
    in
    -- todo: Check whether the update behaviour is correct. There is the implicit assumption that the update originates from the recipe.
    --       cf. name, description
    div [ class "recipeLine" ]
        [ div [ class "plainName" ]
            [ label [] [ text "Name" ]
            , input
                [ value recipeUpdateClientInput.name
                , onInput (flip RecipeUpdateLens.name.set recipeUpdateClientInput >> UpdateRecipe recipeId)
                , createOnEnter
                ]
                []
            ]
        , div [ class "recipeDescriptionArea" ]
            [ label [] [ text "Description" ]
            , div [ class "recipeDescription" ]
                [ input
                    [ Maybe.withDefault "" recipeUpdateClientInput.description |> value
                    , onInput
                        (flip
                            (Just
                                >> Maybe.Extra.filter (String.isEmpty >> not)
                                >> RecipeUpdateLens.description.set
                            )
                            recipeUpdateClientInput
                            >> UpdateRecipe recipeId
                        )
                    , createOnEnter
                    ]
                    []
                ]
            ]
        , button [ class "button", onClick (SaveRecipeEdit recipeId) ]
            [ text "Save" ]
        , button [ class "button", onClick (ExitEditRecipeAt recipeId) ]
            [ text "Cancel" ]
        ]

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CreateRecipe ->
            ( model, createRecipe model )

        GotCreateRecipeResponse graphQLDataOrError ->
            case graphQLDataOrError of
                Success projectInformation ->
                    let
                        newModel =
                            Lens.modify ownRecipesLens
                                (\ts ->
                                    Right
                                        { original = projectInformation
                                        , update = RecipeUpdateClientInput.from projectInformation
                                        }
                                        :: ts
                                )
                                model
                    in
                    ( newModel, Cmd.none )

                _ ->
                    -- todo: Handle error case
                    ( model, Cmd.none )

        UpdateRecipe projectId projectUpdateClientInput ->
            ( model
                |> Optional.modify
                    (ownRecipesLens
                        |> Compose.lensWithOptional
                            (projectIdIs projectId |> LensUtil.firstSuch)
                    )
                    (Either.mapRight (Editing.updateLens.set projectUpdateClientInput))
            , Cmd.none
            )

        SaveRecipeEdit projectId ->
            let
                cmd =
                    Maybe.Extra.unwrap
                        Cmd.none
                        (Either.unwrap Cmd.none
                            (\editing ->
                                saveRecipe model
                                    (RecipeUpdateClientInput.to projectId editing.original.ownerId editing.update |> RecipeInformation.toUpdate)
                                    editing.original.id
                            )
                        )
                        (List.Extra.find (projectIdIs projectId) model.ownRecipes)
            in
            ( model, cmd )

        GotSaveRecipeResponse projectId graphQLDataOrError ->
            case graphQLDataOrError of
                Success project ->
                    ( model
                        |> Optional.modify
                            (ownRecipesLens
                                |> Compose.lensWithOptional (projectIdIs projectId |> LensUtil.firstSuch)
                            )
                            (Either.andThenRight (always (Left project)))
                    , Cmd.none
                    )

                -- todo: Handle error case
                _ ->
                    ( model, Cmd.none )

        EnterEditRecipe projectId ->
            ( model
                |> Optional.modify (ownRecipesLens |> Compose.lensWithOptional (projectIdIs projectId |> LensUtil.firstSuch))
                    (Either.unpack (\project -> { original = project, update = RecipeUpdateClientInput.from project }) identity >> Right)
            , Cmd.none
            )

        ExitEditRecipeAt projectId ->
            ( model |> Optional.modify (ownRecipesLens |> Compose.lensWithOptional (projectIdIs projectId |> LensUtil.firstSuch)) (Either.unpack identity .original >> Left), Cmd.none )

        DeleteRecipe projectId ->
            ( model
            , deleteRecipe model projectId
            )

        GotDeleteRecipeResponse graphQLDataOrError ->
            case graphQLDataOrError of
                Success deletedId ->
                    ( model
                        |> ownRecipesLens.set
                            (model.ownRecipes
                                |> List.Extra.filterNot
                                    (Either.unpack
                                        (\t -> t.id == deletedId)
                                        (\t -> t.original.id == deletedId)
                                    )
                            )
                    , Cmd.none
                    )

                -- todo: Handle error case
                _ ->
                    ( model, Cmd.none )

        GotFetchOwnRecipesResponse graphQLDataOrError ->
            case graphQLDataOrError of
                Success ownRecipes ->
                    ( model |> ownRecipesLens.set (ownRecipes |> List.map Left), Cmd.none )

                -- todo: Handle error case
                _ ->
                    ( model, Cmd.none )

        GotFetchWriteAccessRecipesResponse graphQLDataOrError ->
            case graphQLDataOrError of
                Success writeAccessRecipes ->
                    ( model |> writeAccessRecipesLens.set (writeAccessRecipes |> List.map Left), Cmd.none )

                -- todo: Handle error case
                _ ->
                    ( model, Cmd.none )

fetchRecipes : Configuration -> String -> Cmd Msg
fetchRecipes conf jwt =
    HttpUtil.getJsonWithJWT jwt
        { url = String.join "/" [ conf.backendURL, "recipe", "all" ]
        , expect = HttpUtil.expectJson GotFetchRecipesResponse (Decode.list decoderRecipe)
        }
