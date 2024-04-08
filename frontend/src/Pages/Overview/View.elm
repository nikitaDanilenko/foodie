module Pages.Overview.View exposing (view)

import Addresses.Frontend
import Configuration exposing (Configuration)
import Html exposing (Html, div, text)
import Pages.Overview.Page as Page
import Pages.Util.Links as Links
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate


view : Page.Model -> Html Page.Msg
view =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }


viewMain : Configuration -> Page.Main -> Html Page.LogicMsg
viewMain configuration _ =
    ViewUtil.viewMainWith
        { configuration = configuration
        , currentPage = Just ViewUtil.Overview
        , showNavigation = False
        }
    <|
        div [ Style.ids.overviewMain ]
            [ div []
                [ Links.linkButton
                    { url = Links.frontendPage configuration <| Addresses.Frontend.recipes.address <| ()
                    , attributes = [ Style.classes.button.overview ]
                    , children = [ text "Recipes" ]
                    }
                ]
            , div []
                [ Links.linkButton
                    { url = Links.frontendPage configuration <| Addresses.Frontend.mealBranch.address <| ()
                    , attributes = [ Style.classes.button.overview ]
                    , children = [ text "Meals" ]
                    }
                ]
            , div []
                [ Links.linkButton
                    { url = Links.frontendPage configuration <| Addresses.Frontend.complexFoods.address <| ()
                    , attributes = [ Style.classes.button.overview ]
                    , children = [ text "Complex foods" ]
                    }
                ]
            , div []
                [ Links.linkButton
                    { url = Links.frontendPage configuration <| Addresses.Frontend.statisticsTime.address <| ()
                    , attributes = [ Style.classes.button.overview ]
                    , children = [ text "Statistics" ]
                    }
                ]
            , div []
                [ Links.linkButton
                    { url = Links.frontendPage configuration <| Addresses.Frontend.referenceMaps.address <| ()
                    , attributes = [ Style.classes.button.overview ]
                    , children = [ text "Reference maps" ]
                    }
                ]
            , div []
                [ Links.linkButton
                    { url = Links.frontendPage configuration <| Addresses.Frontend.userSettings.address <| ()
                    , attributes = [ Style.classes.button.overview ]
                    , children = [ text "User settings" ]
                    }
                ]
            ]
