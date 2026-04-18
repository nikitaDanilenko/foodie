module Pages.Ingredients.Recipe.View exposing (viewMain)

import Addresses.Frontend
import Html exposing (Attribute, Html, button, td, text)
import Html.Attributes exposing (disabled)
import Html.Events exposing (onClick)
import Maybe.Extra
import Pages.Ingredients.Recipe.Page as Page
import Pages.Recipes.RecipeUpdateClientInput as RecipeUpdateClientInput
import Pages.Recipes.Util
import Pages.Recipes.View
import Pages.Util.Links as Links
import Pages.Util.Parent.Page
import Pages.Util.Parent.View
import Pages.Util.Style as Style


viewMain : Page.Main -> Html Page.LogicMsg
viewMain main =
    let
        rescalable =
            main.parent.original.servingSize
                |> Maybe.Extra.unwrap False Pages.Recipes.Util.isRescalableServingSize

        rescalableCmd =
            if rescalable then
                [ onClick <| Page.Rescale ]

            else
                []
    in
    Pages.Util.Parent.View.viewMain
        { tableHeader = Pages.Recipes.View.tableHeader
        , onView =
            \recipe showControls ->
                Pages.Recipes.View.recipeLineWith
                    { controls =
                        [ td [ Style.classes.controls ]
                            [ button [ Style.classes.button.edit, onClick <| Page.ParentMsg <| Pages.Util.Parent.Page.EnterEdit ] [ text "Edit" ] ]
                        , td [ Style.classes.controls ]
                            [ button
                                [ Style.classes.button.delete, onClick <| Page.ParentMsg <| Pages.Util.Parent.Page.RequestDelete ]
                                [ text "Delete" ]
                            ]
                        , td [ Style.classes.controls ]
                            [ Links.linkButton
                                { url = Links.frontendPage <| Addresses.Frontend.statisticsRecipeSelect.address <| main.parent.original.id
                                , attributes = [ Style.classes.button.nutrients ]
                                , children = [ text "Nutrients" ]
                                }
                            ]
                        , td [ Style.classes.controls ]
                            [ button
                                [ Style.classes.button.confirm, onClick <| Page.ParentMsg <| Pages.Util.Parent.Page.Duplicate ]
                                [ text "Duplicate" ]
                            ]
                        , td [ Style.classes.controls ]
                            [ button
                                ([ Style.classes.button.rescale
                                 , disabled <| not <| rescalable
                                 ]
                                    ++ rescalableCmd
                                )
                                [ text "Rescale" ]
                            ]
                        ]
                    , toggleMsg = Page.ParentMsg <| Pages.Util.Parent.Page.ToggleControls
                    , showControls = showControls
                    }
                    recipe
        , onUpdate =
            Pages.Recipes.View.editRecipeLineWith
                { saveMsg = Page.ParentMsg <| Pages.Util.Parent.Page.SaveEdit main.parent.original
                , nameLens = RecipeUpdateClientInput.lenses.name
                , descriptionLens = RecipeUpdateClientInput.lenses.description
                , numberOfServingsLens = RecipeUpdateClientInput.lenses.numberOfServings
                , servingSizeLens = RecipeUpdateClientInput.lenses.servingSize
                , updateMsg = Page.ParentMsg << Pages.Util.Parent.Page.Edit
                , confirmName = "Save"
                , cancelMsg = Page.ParentMsg <| Pages.Util.Parent.Page.ExitEdit
                , cancelName = "Cancel"
                , rowStyles = []
                , toggleCommand = Just <| Page.ParentMsg <| Pages.Util.Parent.Page.ToggleControls
                }
                |> always
        , onDelete =
            Pages.Recipes.View.recipeLineWith
                { controls =
                    [ td [ Style.classes.controls ]
                        [ button [ Style.classes.button.delete, onClick <| Page.ParentMsg <| Pages.Util.Parent.Page.ConfirmDelete ] [ text "Delete?" ] ]
                    , td [ Style.classes.controls ]
                        [ button
                            [ Style.classes.button.confirm, onClick <| Page.ParentMsg <| Pages.Util.Parent.Page.CancelDelete ]
                            [ text "Cancel" ]
                        ]
                    ]
                , toggleMsg = Page.ParentMsg <| Pages.Util.Parent.Page.ToggleControls
                , showControls = True
                }
        }
        main
