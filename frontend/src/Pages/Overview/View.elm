module Pages.Overview.View exposing (view)

import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Pages.Overview.Page as Page


view : Page.Model -> Html Page.Msg
view _ =
    div [ id "overviewMain" ]
        [ div [ id "recipesButton" ]
            [ button [ class "button", onClick Page.Recipes ] [ text "Recipes" ] ]
        , div [ id "mealsButton" ]
            [ button [ class "button", onClick Page.Meals ] [ text "Meals" ] ]
        , div [ id "statsButton" ]
            [ button [ class "button", onClick Page.Statistics ] [ text "Statistics" ] ]
        ]
