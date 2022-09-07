module Pages.Recipes exposing (Flags, Model, Msg, init, update, updateJWT, view)

import Api.Auxiliary exposing (JWT, RecipeId)
import Api.Lenses.RecipeUpdateLens as RecipeUpdateLens
import Api.Types.Recipe exposing (Recipe, decoderRecipe)
import Api.Types.RecipeCreation exposing (RecipeCreation, encoderRecipeCreation)
import Api.Types.RecipeUpdate exposing (RecipeUpdate, encoderRecipeUpdate)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Either exposing (Either(..))
import Html exposing (Html, button, div, input, label, td, text, thead, tr)
import Html.Attributes exposing (class, id, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Http exposing (Error)
import Json.Decode as Decode
import List.Extra
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens as Lens exposing (Lens)
import Monocle.Optional as Optional
import Pages.Util.Links as Links
import Ports exposing (doFetchToken)
import Url.Builder
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil as HttpUtil
import Util.LensUtil as LensUtil


type alias Model =
    { configuration : Configuration
    , jwt : String
    , recipes : List (Either Recipe (Editing Recipe RecipeUpdate))
    }


jwtLens : Lens Model String
jwtLens =
    Lens .jwt (\b a -> { a | jwt = b })


recipesLens : Lens Model (List (Either Recipe (Editing Recipe RecipeUpdate)))
recipesLens =
    Lens .recipes (\b a -> { a | recipes = b })


type Msg
    = CreateRecipe
    | GotCreateRecipeResponse (Result Error Recipe)
    | UpdateRecipe RecipeId RecipeUpdate
    | SaveRecipeEdit RecipeId
    | GotSaveRecipeResponse RecipeId (Result Error Recipe)
    | EnterEditRecipe RecipeId
    | ExitEditRecipeAt RecipeId
    | DeleteRecipe RecipeId
    | GotDeleteRecipeResponse RecipeId (Result Error ())
    | GotFetchRecipesResponse (Result Error (List Recipe))
    | UpdateJWT String


updateJWT : String -> Msg
updateJWT =
    UpdateJWT


type alias Flags =
    { configuration : Configuration
    , jwt : Maybe String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( jwt, cmd ) =
            case flags.jwt of
                Just token ->
                    ( token, fetchRecipes flags.configuration token )

                Nothing ->
                    ( "", doFetchToken () )
    in
    ( { configuration = flags.configuration
      , jwt = jwt
      , recipes = []
      }
    , cmd
    )


view : Model -> Html Msg
view model =
    let
        viewEditRecipes =
            List.map
                (Either.unpack
                    (editOrDeleteRecipeLine model.configuration)
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


editOrDeleteRecipeLine : Configuration -> Recipe -> Html Msg
editOrDeleteRecipeLine configuration recipe =
    tr [ id "editingRecipe" ]
        [ td [] [ label [] [ text recipe.name ] ]
        , td [] [ label [] [ recipe.description |> Maybe.withDefault "" |> text ] ]
        , td [] [ button [ class "button", onClick (EnterEditRecipe recipe.id) ] [ text "Edit" ] ]
        , td []
            [ Links.linkButton
                { url =
                    Url.Builder.relative
                        [ configuration.mainPageURL
                        , "#"
                        , "ingredient-editor"
                        , recipe.id
                        ]
                        []
                , attributes = [ class "button" ]
                , children = [ text "Edit ingredients" ]
                , isDisabled = False
                }
            ]
        , td [] [ button [ class "button", onClick (DeleteRecipe recipe.id) ] [ text "Delete" ] ]
        ]


editRecipeLine : RecipeId -> RecipeUpdate -> Html Msg
editRecipeLine recipeId recipeUpdate =
    let
        saveOnEnter =
            onEnter (SaveRecipeEdit recipeId)
    in
    -- todo: Check whether the update behaviour is correct. There is the implicit assumption that the update originates from the recipe.
    --       cf. name, description
    div [ class "recipeLine" ]
        [ div [ class "name" ]
            [ label [] [ text "Name" ]
            , input
                [ value recipeUpdate.name
                , onInput (flip RecipeUpdateLens.name.set recipeUpdate >> UpdateRecipe recipeId)
                , saveOnEnter
                ]
                []
            ]
        , div [ class "recipeDescriptionArea" ]
            [ label [] [ text "Description" ]
            , div [ class "recipeDescription" ]
                [ input
                    [ Maybe.withDefault "" recipeUpdate.description |> value
                    , onInput
                        (flip
                            (Just
                                >> Maybe.Extra.filter (String.isEmpty >> not)
                                >> RecipeUpdateLens.description.set
                            )
                            recipeUpdate
                            >> UpdateRecipe recipeId
                        )
                    , saveOnEnter
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

        GotCreateRecipeResponse dataOrError ->
            case dataOrError of
                Ok recipe ->
                    let
                        newModel =
                            Lens.modify recipesLens
                                (\ts ->
                                    Right
                                        { original = recipe
                                        , update = recipeUpdateFromRecipe recipe
                                        }
                                        :: ts
                                )
                                model
                    in
                    ( newModel, Cmd.none )

                _ ->
                    -- todo: Handle error case
                    ( model, Cmd.none )

        UpdateRecipe recipeId recipeUpdate ->
            ( model
                |> Optional.modify
                    (recipesLens
                        |> Compose.lensWithOptional
                            (recipeIdIs recipeId |> LensUtil.firstSuch)
                    )
                    (Either.mapRight (Editing.updateLens.set recipeUpdate))
            , Cmd.none
            )

        SaveRecipeEdit recipeId ->
            let
                cmd =
                    Maybe.Extra.unwrap
                        Cmd.none
                        (Either.unwrap Cmd.none
                            (.update
                                >> saveRecipe model
                            )
                        )
                        (List.Extra.find (recipeIdIs recipeId) model.recipes)
            in
            ( model, cmd )

        GotSaveRecipeResponse recipeId graphQLDataOrError ->
            case graphQLDataOrError of
                Ok recipe ->
                    ( model
                        |> Optional.modify
                            (recipesLens
                                |> Compose.lensWithOptional (recipeIdIs recipeId |> LensUtil.firstSuch)
                            )
                            (Either.andThenRight (always (Left recipe)))
                    , Cmd.none
                    )

                -- todo: Handle error case
                _ ->
                    ( model, Cmd.none )

        EnterEditRecipe recipeId ->
            ( model
                |> Optional.modify (recipesLens |> Compose.lensWithOptional (recipeIdIs recipeId |> LensUtil.firstSuch))
                    (Either.unpack (\recipe -> { original = recipe, update = recipeUpdateFromRecipe recipe }) identity >> Right)
            , Cmd.none
            )

        ExitEditRecipeAt recipeId ->
            ( model |> Optional.modify (recipesLens |> Compose.lensWithOptional (recipeIdIs recipeId |> LensUtil.firstSuch)) (Either.unpack identity .original >> Left), Cmd.none )

        DeleteRecipe recipeId ->
            ( model
            , deleteRecipe model recipeId
            )

        GotDeleteRecipeResponse deletedId dataOrError ->
            case dataOrError of
                Ok _ ->
                    ( model
                        |> recipesLens.set
                            (model.recipes
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

        GotFetchRecipesResponse dataOrError ->
            case dataOrError of
                Ok ownRecipes ->
                    ( model |> recipesLens.set (ownRecipes |> List.map Left), Cmd.none )

                -- todo: Handle error case
                _ ->
                    ( model, Cmd.none )

        UpdateJWT jwt ->
            ( jwtLens.set jwt model, fetchRecipes model.configuration model.jwt )


recipeIdIs : RecipeId -> Either Recipe (Editing Recipe RecipeUpdate) -> Bool
recipeIdIs recipeId =
    Either.unpack
        (\p -> p.id == recipeId)
        (\e -> e.original.id == recipeId)


recipeUpdateFromRecipe : Recipe -> RecipeUpdate
recipeUpdateFromRecipe r =
    { id = r.id
    , name = r.name
    , description = r.description
    }


fetchRecipes : Configuration -> JWT -> Cmd Msg
fetchRecipes conf jwt =
    HttpUtil.getJsonWithJWT jwt
        { url = Url.Builder.relative [ conf.backendURL, "recipe", "all" ] []
        , expect = HttpUtil.expectJson GotFetchRecipesResponse (Decode.list decoderRecipe)
        }


createRecipe : Model -> Cmd Msg
createRecipe md =
    let
        defaultRecipeCreation =
            { name = ""
            , description = Nothing
            }
    in
    HttpUtil.postJsonWithJWT md.jwt
        { url = Url.Builder.relative [ md.configuration.backendURL, "recipe", "create" ] []
        , body = encoderRecipeCreation defaultRecipeCreation
        , expect = HttpUtil.expectJson GotCreateRecipeResponse decoderRecipe
        }


saveRecipe : Model -> RecipeUpdate -> Cmd Msg
saveRecipe md ru =
    HttpUtil.patchJsonWithJWT md.jwt
        { url = Url.Builder.relative [ md.configuration.backendURL, "recipe", "update" ] []
        , body = encoderRecipeUpdate ru
        , expect = HttpUtil.expectJson (GotSaveRecipeResponse ru.id) decoderRecipe
        }


deleteRecipe : Model -> RecipeId -> Cmd Msg
deleteRecipe md rId =
    HttpUtil.deleteWithJWT md.jwt
        { url = Url.Builder.relative [ md.configuration.backendURL, "recipe", "delete", rId ] []
        , expect = HttpUtil.expectWhatever (GotDeleteRecipeResponse rId)
        }
