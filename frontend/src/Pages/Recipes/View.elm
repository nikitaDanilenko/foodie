module Pages.Recipes.View exposing (view)

import Addresses.Frontend
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Dict
import Either exposing (Either(..))
import Html exposing (Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, disabled, scope, value)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Recipes.Page as Page
import Pages.Recipes.Pagination as Pagination
import Pages.Recipes.RecipeCreationClientInput as RecipeCreationClientInput exposing (RecipeCreationClientInput)
import Pages.Recipes.RecipeUpdateClientInput as RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Recipes.Status as Status
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)
import Pages.Util.ViewUtil as ViewUtil
import Paginate
import Util.Editing as Editing


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = Page.lenses.initialization.get
        , configuration = .flagsWithJWT >> .configuration
        , jwt = .flagsWithJWT >> .jwt >> Just
        , currentPage = Just ViewUtil.Recipes
        , showNavigation = True
        }
        model
    <|
        let
            viewEditRecipe =
                Either.unpack
                    (editOrDeleteRecipeLine model.flagsWithJWT.configuration)
                    (\e -> e.update |> editRecipeLine)

            viewEditRecipes =
                model.recipes
                    |> Dict.values
                    |> List.sortBy (Editing.field .name >> String.toLower)
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.pagination |> Compose.lensWithLens Pagination.lenses.recipes
                        }
                        model

            ( button, creationLine ) =
                createRecipe model.recipeToAdd |> Either.unpack (\l -> ( [ l ], [] )) (\r -> ( [], [ r ] ))
        in
        div [ Style.ids.addRecipeView ]
            (button
                ++ [ table []
                        [ colgroup []
                            [ col [] []
                            , col [] []
                            , col [] []
                            , col [ stringProperty "span" "3" ] []
                            ]
                        , thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                                , th [ scope "col" ] [ label [] [ text "Description" ] ]
                                , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text "Servings" ] ]
                                , th [ colspan 3, scope "colgroup", Style.classes.controlsGroup ] []
                                ]
                            ]
                        , tbody []
                            (creationLine
                                ++ (viewEditRecipes |> Paginate.page |> List.map viewEditRecipe)
                            )
                        ]
                   , div [ Style.classes.pagination ]
                        [ ViewUtil.pagerButtons
                            { msg =
                                PaginationSettings.updateCurrentPage
                                    { pagination = Page.lenses.pagination
                                    , items = Pagination.lenses.recipes
                                    }
                                    model
                                    >> Page.SetPagination
                            , elements = viewEditRecipes
                            }
                        ]
                   ]
            )


createRecipe : Maybe RecipeCreationClientInput -> Either (Html Page.Msg) (Html Page.Msg)
createRecipe maybeCreation =
    case maybeCreation of
        Nothing ->
            div [ Style.ids.add ]
                [ button
                    [ Style.classes.button.add
                    , onClick <| Page.UpdateRecipeCreation <| Just <| RecipeCreationClientInput.default
                    ]
                    [ text "New recipe" ]
                ]
                |> Left

        Just creation ->
            createRecipeLine creation |> Right


editOrDeleteRecipeLine : Configuration -> Recipe -> Html Page.Msg
editOrDeleteRecipeLine configuration recipe =
    let
        editMsg =
            Page.EnterEditRecipe recipe.id
    in
    tr [ Style.classes.editing ]
        [ td [ Style.classes.editable, onClick editMsg ] [ label [] [ text recipe.name ] ]
        , td [ Style.classes.editable, onClick editMsg ] [ label [] [ text <| Maybe.withDefault "" <| recipe.description ] ]
        , td [ Style.classes.editable, Style.classes.numberLabel, onClick editMsg ] [ label [] [ text <| String.fromFloat <| recipe.numberOfServings ] ]
        , td [ Style.classes.controls ]
            [ button [ Style.classes.button.edit, onClick editMsg ] [ text "Edit" ] ]
        , td [ Style.classes.controls ]
            [ button
                [ Style.classes.button.delete, onClick (Page.DeleteRecipe recipe.id) ]
                [ text "Delete" ]
            ]
        , td [ Style.classes.controls ]
            [ Links.linkButton
                { url = Links.frontendPage configuration <| Addresses.Frontend.ingredientEditor.address <| recipe.id
                , attributes = [ Style.classes.button.editor ]
                , children = [ text "Ingredients" ]
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
        , confirmName = "Save"
        , cancelMsg = Page.ExitEditRecipeAt recipeUpdateClientInput.id
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
        , confirmName = "Add"
        , cancelMsg = Page.UpdateRecipeCreation Nothing
        , cancelName = "Cancel"
        }
        recipeCreationClientInput


editRecipeLineWith :
    { saveMsg : Page.Msg
    , nameLens : Lens editedValue (ValidatedInput String)
    , descriptionLens : Lens editedValue (Maybe String)
    , numberOfServingsLens : Lens editedValue (ValidatedInput Float)
    , updateMsg : editedValue -> Page.Msg
    , confirmName : String
    , cancelMsg : Page.Msg
    , cancelName : String
    }
    -> editedValue
    -> Html Page.Msg
editRecipeLineWith handling editedValue =
    let
        validInput =
            handling.nameLens.get editedValue
                |> .value
                |> String.isEmpty
                |> not

        validatedSaveAction =
            if validInput then
                [ onEnter handling.saveMsg ]

            else
                []
    in
    tr [ Style.classes.editLine ]
        [ td [ Style.classes.editable ]
            [ input
                ([ value <| .text <| handling.nameLens.get <| editedValue
                 , onInput
                    (flip (ValidatedInput.lift handling.nameLens).set editedValue
                        >> handling.updateMsg
                    )
                 , HtmlUtil.onEscape handling.cancelMsg
                 ]
                    ++ validatedSaveAction
                )
                []
            ]
        , td [ Style.classes.editable ]
            [ input
                ([ value <| Maybe.withDefault "" <| handling.descriptionLens.get <| editedValue
                 , onInput
                    (flip
                        (Just
                            >> Maybe.Extra.filter (String.isEmpty >> not)
                            >> handling.descriptionLens.set
                        )
                        editedValue
                        >> handling.updateMsg
                    )
                 , HtmlUtil.onEscape handling.cancelMsg
                 ]
                    ++ validatedSaveAction
                )
                []
            ]
        , td [ Style.classes.numberCell ]
            [ input
                ([ value <| .text <| handling.numberOfServingsLens.get <| editedValue
                 , onInput
                    (flip
                        (ValidatedInput.lift
                            handling.numberOfServingsLens
                        ).set
                        editedValue
                        >> handling.updateMsg
                    )
                 , HtmlUtil.onEscape handling.cancelMsg
                 , Style.classes.numberLabel
                 ]
                    ++ validatedSaveAction
                )
                []
            ]
        , td [ Style.classes.controls ]
            [ button
                [ Style.classes.button.confirm
                , onClick handling.saveMsg
                , disabled <| not <| validInput
                ]
                [ text handling.confirmName ]
            ]
        , td [ Style.classes.controls ]
            [ button [ Style.classes.button.cancel, onClick handling.cancelMsg ]
                [ text handling.cancelName ]
            ]
        , td [] []
        ]
