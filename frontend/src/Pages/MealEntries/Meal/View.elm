module Pages.MealEntries.Meal.View exposing (..)

import Addresses.Frontend
import Api.Types.Profile exposing (Profile)
import Html exposing (Attribute, Html, button, td, text)
import Html.Events exposing (onClick)
import Pages.MealEntries.Meal.Page as Page
import Pages.Meals.Editor.MealUpdateClientInput as MealUpdateClientInput
import Pages.Meals.Editor.View
import Pages.Util.Links as Links
import Pages.Util.Parent.Page
import Pages.Util.Parent.View
import Pages.Util.Style as Style


viewMain : Profile -> Page.Main -> Html Page.LogicMsg
viewMain profile main =
    Pages.Util.Parent.View.viewMain
        { tableHeader = Pages.Meals.Editor.View.tableHeader
        , onView =
            \meal showControls ->
                Pages.Meals.Editor.View.mealLineWith
                    { controls =
                        [ td [ Style.classes.controls ]
                            [ button [ Style.classes.button.edit, Pages.Util.Parent.Page.EnterEdit |> onClick ] [ text "Edit" ] ]
                        , td [ Style.classes.controls ]
                            [ button
                                [ Style.classes.button.delete, Pages.Util.Parent.Page.RequestDelete |> onClick ]
                                [ text "Delete" ]
                            ]
                        , td [ Style.classes.controls ]
                            [ Links.linkButton
                                { url = Links.frontendPage <| Addresses.Frontend.statisticsMealSelect.address <| ( profile.id, main.parent.original.id )
                                , attributes = [ Style.classes.button.nutrients ]
                                , children = [ text "Nutrients" ]
                                }
                            ]
                        , td [ Style.classes.controls ]
                            [ button
                                [ Style.classes.button.confirm, Pages.Util.Parent.Page.Duplicate |> onClick ]
                                [ text "Duplicate" ]
                            ]
                        ]
                    , toggleMsg = Pages.Util.Parent.Page.ToggleControls
                    , showControls = showControls
                    }
                    profile.name
                    meal
        , onUpdate =
            Pages.Meals.Editor.View.editMealLineWith
                { saveMsg = Pages.Util.Parent.Page.SaveEdit main.parent.original
                , dateLens = MealUpdateClientInput.lenses.date
                , nameLens = MealUpdateClientInput.lenses.name
                , updateMsg = Pages.Util.Parent.Page.Edit
                , confirmName = "Save"
                , cancelMsg = Pages.Util.Parent.Page.ExitEdit
                , cancelName = "Cancel"
                , rowStyles = []
                , toggleCommand = Just Pages.Util.Parent.Page.ToggleControls
                }
                profile.name
                |> always
        , onDelete =
            Pages.Meals.Editor.View.mealLineWith
                { controls =
                    [ td [ Style.classes.controls ]
                        [ button [ Style.classes.button.delete, onClick <| Pages.Util.Parent.Page.ConfirmDelete ] [ text "Delete?" ] ]
                    , td [ Style.classes.controls ]
                        [ button
                            [ Style.classes.button.confirm, onClick <| Pages.Util.Parent.Page.CancelDelete ]
                            [ text "Cancel" ]
                        ]
                    ]
                , toggleMsg = Pages.Util.Parent.Page.ToggleControls
                , showControls = True
                }
                profile.name
        }
        main
