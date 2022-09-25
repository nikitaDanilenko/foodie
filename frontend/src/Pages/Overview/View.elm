module Pages.Overview.View exposing (view)

import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Pages.Overview.Page as Page
import Pages.Overview.Status as Status
import Pages.Util.Style as Style
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
        div [ Style.ids.overviewMain ]
            [ div [ Style.ids.recipesButton ]
                [ button [ onClick Page.Recipes ] [ text "Recipes" ] ]
            , div [ Style.ids.mealsButton ]
                [ button [ onClick Page.Meals ] [ text "Meals" ] ]
            , div [ Style.ids.statisticsButton ]
                [ button [ onClick Page.Statistics ] [ text "Statistics" ] ]
            , div [ Style.ids.referenceNutrientsButton ]
                [ button [ onClick Page.ReferenceNutrients ] [ text "Reference nutrients" ] ]
            ]
