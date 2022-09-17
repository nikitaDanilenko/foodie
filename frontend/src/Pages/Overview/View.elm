module Pages.Overview.View exposing (view)

import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Pages.Overview.Page as Page
import Pages.Overview.Status as Status
import Pages.Util.ViewUtil as ViewUtil


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = .initialization
        , flagsWithJWT = .flagsWithJWT
        }
        model
    <|
        div [ id "overviewMain" ]
            [ div [ id "recipesButton" ]
                [ button [ class "button", onClick Page.Recipes ] [ text "Recipes" ] ]
            , div [ id "mealsButton" ]
                [ button [ class "button", onClick Page.Meals ] [ text "Meals" ] ]
            , div [ id "statisticsButton" ]
                [ button [ class "button", onClick Page.Statistics ] [ text "Statistics" ] ]
            , div [ id "referenceNutrientsButton" ]
                [ button [ class "button", onClick Page.ReferenceNutrients ] [ text "Reference nutrients" ] ]
            ]
