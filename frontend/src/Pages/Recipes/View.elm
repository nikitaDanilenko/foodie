module Pages.Recipes.View exposing (view)

import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Dict
import Either exposing (Either(..))
import Html exposing (Html, button, div, input, label, td, text, thead, tr)
import Html.Attributes exposing (class, id, value)
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
        in
        div [ id "addRecipeView" ]
            (createRecipe model.recipeToAdd
                :: thead []
                    [ tr [ class "tableHeader" ]
                        [ td [] [ label [] [ text "Name" ] ]
                        , td [] [ label [] [ text "Description" ] ]
                        , td [] [ label [] [ text "Servings" ] ]
                        ]
                    ]
                :: viewEditRecipes
                    (model.recipes
                        |> Dict.values
                        |> List.sortBy (Editing.field .name >> String.toLower)
                    )
            )


createRecipe maybeCreation =
    case maybeCreation of
        Nothing ->
            div [ id "addRecipe" ]
                [ button
                    [ class "addRecipeButton"
                    , onClick <| Page.UpdateRecipeCreation <| Just <| RecipeCreationClientInput.default
                    ]
                    [ text "New recipe" ]
                ]

        Just creation ->
            createRecipeLine creation


editOrDeleteRecipeLine : Configuration -> Recipe -> Html Page.Msg
editOrDeleteRecipeLine configuration recipe =
    tr [ id "editingRecipe" ]
        [ td [ class "editable" ] [ label [] [ text recipe.name ] ]
        , td [ class "editable" ] [ label [] [ text <| Maybe.withDefault "" <| recipe.description ] ]
        , td [ class "editable", class "numberLabel" ] [ label [] [ text <| String.fromFloat <| recipe.numberOfServings ] ]
        , td []
            [ button [ class "editButton", onClick (Page.EnterEditRecipe recipe.id) ] [ text "Edit" ]
            , Links.linkButton
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
            , button
                [ class "deleteButton", onClick (Page.DeleteRecipe recipe.id) ]
                [ text "Delete" ]
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
    tr [ id "recipeLine" ]
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
        , td [ class "editable" ]
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
        , td []
            [ button [ class "confirmButton", onClick handling.confirmOnClick ]
                [ text handling.confirmName ]
            , button [ class "cancelButton", onClick handling.cancelOnClick ]
                [ text handling.cancelName ]
            ]
        ]
