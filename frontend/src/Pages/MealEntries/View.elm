module Pages.MealEntries.View exposing (view)

import Html exposing (Attribute, Html, div, label, text)
import Pages.MealEntries.Entries.View
import Pages.MealEntries.Meal.View
import Pages.MealEntries.Page as Page
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate


view : Page.Model -> Html Page.Msg
view =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }


viewMain : Page.Main -> Html Page.LogicMsg
viewMain main =
    ViewUtil.viewMainWith
        { currentPage = Nothing
        , showNavigation = True
        }
    <|
        div [ Style.ids.mealEntryEditor ]
            [ div []
                [ Pages.MealEntries.Meal.View.viewMain main.profile main.meal
                    |> Html.map Page.MealMsg
                ]
            , div [ Style.classes.elements ] [ label [] [ text "Dishes" ] ]
            , Pages.MealEntries.Entries.View.viewMealEntries main.entries |> Html.map Page.EntriesMsg
            , div [ Style.classes.elements ] [ label [] [ text "Recipes" ] ]
            , Pages.MealEntries.Entries.View.viewRecipes main.entries |> Html.map Page.EntriesMsg
            ]
