module Pages.Recipes.View exposing (view)

import Api.Auxiliary exposing (JWT, RecipeId)
import Api.Lenses.RecipeUpdateLens as RecipeUpdateLens
import Api.Types.Recipe exposing (Recipe)
import Api.Types.RecipeUpdate exposing (RecipeUpdate)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Either exposing (Either(..))
import Html exposing (Html, button, div, input, label, td, text, thead, tr)
import Html.Attributes exposing (class, id, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.Recipes.Page as Page
import Pages.Util.Links as Links
import Url.Builder
import Util.Editing exposing (Editing)


view : Page.Model -> Html Page.Msg
view model =
    let
        viewEditRecipes =
            List.map
                (Either.unpack
                    (editOrDeleteRecipeLine model.flagsWithJWT.configuration)
                    (\e -> e.update |> editRecipeLine e.original.id)
                )
    in
    div [ id "addRecipeView" ]
        (div [ id "addRecipe" ] [ button [ class "button", onClick Page.CreateRecipe ] [ text "New recipe" ] ]
            :: thead []
                [ tr []
                    [ td [] [ label [] [ text "Name" ] ]
                    , td [] [ label [] [ text "Description" ] ]
                    ]
                ]
            :: viewEditRecipes model.recipes
        )


editOrDeleteRecipeLine : Configuration -> Recipe -> Html Page.Msg
editOrDeleteRecipeLine configuration recipe =
    tr [ id "editingRecipe" ]
        [ td [] [ label [] [ text recipe.name ] ]
        , td [] [ label [] [ recipe.description |> Maybe.withDefault "" |> text ] ]
        , td [] [ button [ class "button", onClick (Page.EnterEditRecipe recipe.id) ] [ text "Edit" ] ]
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
        , td [] [ button [ class "button", onClick (Page.DeleteRecipe recipe.id) ] [ text "Delete" ] ]
        ]


editRecipeLine : RecipeId -> RecipeUpdate -> Html Page.Msg
editRecipeLine recipeId recipeUpdate =
    let
        saveOnEnter =
            onEnter (Page.SaveRecipeEdit recipeId)
    in
    tr [ id "recipeLine" ]
        [ td []
            [ input
                [ value recipeUpdate.name
                , onInput (flip RecipeUpdateLens.name.set recipeUpdate >> Page.UpdateRecipe)
                , saveOnEnter
                ]
                []
            ]
        , td []
            [ input
                [ Maybe.withDefault "" recipeUpdate.description |> value
                , onInput
                    (flip
                        (Just
                            >> Maybe.Extra.filter (String.isEmpty >> not)
                            >> RecipeUpdateLens.description.set
                        )
                        recipeUpdate
                        >> Page.UpdateRecipe
                    )
                , saveOnEnter
                ]
                []
            ]
        , td []
            [ button [ class "button", onClick (Page.SaveRecipeEdit recipeId) ]
                [ text "Save" ]
            ]
        , td []
            [ button [ class "button", onClick (Page.ExitEditRecipeAt recipeId) ]
                [ text "Cancel" ]
            ]
        ]
