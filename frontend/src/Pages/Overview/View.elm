module Pages.Overview.View exposing (view)

import Addresses.Frontend
import Html exposing (Html, div, text)
import Pages.Overview.Page as Page
import Pages.Overview.Status as Status
import Pages.Util.Links as Links
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = .initialization
        , configuration = .flagsWithJWT >> .configuration
        , jwt = .flagsWithJWT >> .jwt >> Just
        , currentPage = Just ViewUtil.Overview
        , showNavigation = False
        }
        model
    <|
        div [ Style.ids.overviewMain ]
            [ div []
                [ Links.linkButton
                    { url = Links.frontendPage model.flagsWithJWT.configuration <| Addresses.Frontend.recipes.address <| ()
                    , attributes = [ Style.ids.recipesButton ]
                    , children = [ text "Recipes" ]
                    }
                ]
            , div []
                [ Links.linkButton
                    { url = Links.frontendPage model.flagsWithJWT.configuration <| Addresses.Frontend.meals.address <| ()
                    , attributes = [ Style.ids.mealsButton ]
                    , children = [ text "Meals" ]
                    }
                ]
            , div []
                [ Links.linkButton
                    { url = Links.frontendPage model.flagsWithJWT.configuration <| Addresses.Frontend.statistics.address <| ()
                    , attributes = [ Style.ids.statisticsButton ]
                    , children = [ text "Statistics" ]
                    }
                ]
            , div []
                [ Links.linkButton
                    { url = Links.frontendPage model.flagsWithJWT.configuration <| Addresses.Frontend.referenceNutrients.address <| ()
                    , attributes = [ Style.ids.referenceNutrientsButton ]
                    , children = [ text "Reference nutrients" ]
                    }
                ]
            , div []
                [ Links.linkButton
                    { url = Links.frontendPage model.flagsWithJWT.configuration <| Addresses.Frontend.userSettings.address <| ()
                    , attributes = [ Style.ids.userSettingsButton ]
                    , children = [ text "User settings" ]
                    }
                ]
            ]
