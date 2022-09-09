module Pages.MealEntryEditor.View exposing (view)

import Html exposing (Html, div)
import Html.Attributes exposing (id)
import Pages.MealEntryEditor.Page


view : Pages.MealEntryEditor.Page.Model -> Html Pages.MealEntryEditor.Page.Msg
view _ =
    div [ id "mealEntryEditor" ] []
