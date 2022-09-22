module Pages.Recipes.View exposing (view)

import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Dict
import Either exposing (Either(..))
import Html exposing (Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, colspan, id, scope, value)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.Recipes.Page as Page
import Pages.Recipes.RecipeCreationClientInput as RecipeCreationClientInput exposing (RecipeCreationClientInput)
import Pages.Recipes.RecipeUpdateClientInput as RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Recipes.Status as Status
import Pages.Util.Links as Links
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)
import Pages.Util.ViewUtil as ViewUtil
import Url.Builder
import Util.Editing as Editing


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = Page.lenses.initialization.get
        , flagsWithJWT = .flagsWithJWT
        }
        model
    <|
        let
            viewEditRecipes =
                List.map
                    (Either.unpack
                        (editOrDeleteRecipeLine model.flagsWithJWT.configuration)
                        (\e -> e.update |> editRecipeLine)
                    )

            ( button, creationLine ) =
                createRecipe model.recipeToAdd |> Either.unpack (\l -> ( [ l ], [] )) (\r -> ( [], [ r ] ))
        in
        div [ id "addRecipeView" ]
            (button
                ++ [ table []
                        [ colgroup []
                            [ col [] []
                            , col [] []
                            , col [] []
                            , col [ stringProperty "span" "3" ] []
                            ]
                        , thead []
                            [ tr [ class "tableHeader" ]
                                [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                                , th [ scope "col" ] [ label [] [ text "Description" ] ]
                                , th [ scope "col", class "numberLabel" ] [ label [] [ text "Servings" ] ]
                                , th [ colspan 3, scope "colgroup", class "controlsGroup" ] []
                                ]
                            ]
                        , tbody []
                            (creationLine
                                ++ viewEditRecipes
                                    (model.recipes
                                        |> Dict.values
                                        |> List.sortBy (Editing.field .name >> String.toLower)
                                    )
                            )
                        ]
                   ]
            )


createRecipe : Maybe RecipeCreationClientInput -> Either (Html Page.Msg) (Html Page.Msg)
createRecipe maybeCreation =
    case maybeCreation of
        Nothing ->
            div [ id "add" ]
                [ button
                    [ class "addButton"
                    , onClick <| Page.UpdateRecipeCreation <| Just <| RecipeCreationClientInput.default
                    ]
                    [ text "New recipe" ]
                ]
                |> Left

        Just creation ->
            createRecipeLine creation |> Right


editOrDeleteRecipeLine : Configuration -> Recipe -> Html Page.Msg
editOrDeleteRecipeLine configuration recipe =
    tr [ class "editing" ]
        [ td [ class "editable" ] [ label [] [ text recipe.name ] ]
        , td [ class "editable" ] [ label [] [ text <| Maybe.withDefault "" <| recipe.description ] ]
        , td [ class "editable", class "numberLabel" ] [ label [] [ text <| String.fromFloat <| recipe.numberOfServings ] ]
        , td [ class "controls" ]
            [ button [ class "editButton", onClick (Page.EnterEditRecipe recipe.id) ] [ text "Edit" ] ]
        , td [ class "controls" ]
            [ button
                [ class "deleteButton", onClick (Page.DeleteRecipe recipe.id) ]
                [ text "Delete" ]
            ]
        , td [ class "controls" ]
            [ Links.linkButton
                { url =
                    Url.Builder.relative
                        [ configuration.mainPageURL
                        , "#"
                        , "ingredient-editor"
                        , recipe.id
                        ]
                        []
                , attributes = [ class "editorButton" ]
                , children = [ text "Edit ingredients" ]
                , isDisabled = False
                }
            ]
        ]


editRecipeLine : RecipeUpdateClientInput -> Html Page.Msg
editRecipeLine recipeUpdateClientInput =
    editRecipeLineWith
        { saveMsg = Page.SaveRecipeEdit recipeUpdateClientInput.id
        , nameLens = RecipeUpdateClientInput.lenses.name
        , descriptionLens = RecipeUpdateClientInput.lenses.description
        , numberOfServingsLens = RecipeUpdateClientInput.lenses.numberOfServings
        , updateMsg = Page.UpdateRecipe
        , confirmOnClick = Page.SaveRecipeEdit recipeUpdateClientInput.id
        , confirmName = "Save"
        , cancelOnClick = Page.ExitEditRecipeAt recipeUpdateClientInput.id
        , cancelName = "Cancel"
        }
        recipeUpdateClientInput


createRecipeLine : RecipeCreationClientInput -> Html Page.Msg
createRecipeLine recipeCreationClientInput =
    editRecipeLineWith
        { saveMsg = Page.CreateRecipe
        , nameLens = RecipeCreationClientInput.lenses.name
        , descriptionLens = RecipeCreationClientInput.lenses.description
        , numberOfServingsLens = RecipeCreationClientInput.lenses.numberOfServings
        , updateMsg = Just >> Page.UpdateRecipeCreation
        , confirmOnClick = Page.CreateRecipe
        , confirmName = "Add"
        , cancelOnClick = Page.UpdateRecipeCreation Nothing
        , cancelName = "Cancel"
        }
        recipeCreationClientInput


editRecipeLineWith :
    { saveMsg : Page.Msg
    , nameLens : Lens editedValue (ValidatedInput String)
    , descriptionLens : Lens editedValue (Maybe String)
    , numberOfServingsLens : Lens editedValue (ValidatedInput Float)
    , updateMsg : editedValue -> Page.Msg
    , confirmOnClick : Page.Msg
    , confirmName : String
    , cancelOnClick : Page.Msg
    , cancelName : String
    }
    -> editedValue
    -> Html Page.Msg
editRecipeLineWith handling editedValue =
    tr [ class "editLine" ]
        [ td [ class "editable" ]
            [ input
                [ value <| .value <| handling.nameLens.get <| editedValue
                , onInput
                    (flip (ValidatedInput.lift handling.nameLens).set editedValue
                        >> handling.updateMsg
                    )
                , onEnter handling.saveMsg
                ]
                []
            ]
        , td [ class "editable" ]
            [ input
                [ value <| Maybe.withDefault "" <| handling.descriptionLens.get <| editedValue
                , onInput
                    (flip
                        (Just
                            >> Maybe.Extra.filter (String.isEmpty >> not)
                            >> handling.descriptionLens.set
                        )
                        editedValue
                        >> handling.updateMsg
                    )
                , onEnter handling.saveMsg
                ]
                []
            ]
        , td [ class "numberCell" ]
            [ input
                [ value <| String.fromFloat <| .value <| handling.numberOfServingsLens.get <| editedValue
                , onInput
                    (flip
                        (ValidatedInput.lift
                            handling.numberOfServingsLens
                        ).set
                        editedValue
                        >> handling.updateMsg
                    )
                , onEnter handling.saveMsg
                , class "numberLabel"
                ]
                []
            ]
        , td [ class "controls" ]
            [ button [ class "confirmButton", onClick handling.confirmOnClick ]
                [ text handling.confirmName ]
            ]
        , td [ class "controls" ]
            [ button [ class "cancelButton", onClick handling.cancelOnClick ]
                [ text handling.cancelName ]
            ]
        , td [] []
        ]
