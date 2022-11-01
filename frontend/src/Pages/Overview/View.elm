module Pages.Overview.View exposing (view)

import Addresses.Frontend
import Html exposing (Html, div, text)
import Pages.Overview.Page as Page
import Pages.Util.Links as Links
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = always True
        , initialization = .initialization
        , configuration = .authorizedAccess >> .configuration
        , jwt = .authorizedAccess >> .jwt >> Just
        , currentPage = Just ViewUtil.Overview
        , showNavigation = False
        }
        model
    <|
        div [ Style.ids.overviewMain ]
            [ div []
                [ Links.linkButton
                    { url = Links.frontendPage model.authorizedAccess.configuration <| Addresses.Frontend.recipes.address <| ()
                    , attributes = [ Style.classes.button.overview ]
                    , children = [ text "Recipes" ]
                    }
                ]
            , div []
                [ Links.linkButton
                    { url = Links.frontendPage model.authorizedAccess.configuration <| Addresses.Frontend.meals.address <| ()
                    , attributes = [ Style.classes.button.overview ]
                    , children = [ text "Meals" ]
                    }
                ]
            , div []
                [ Links.linkButton
                    { url = Links.frontendPage model.authorizedAccess.configuration <| Addresses.Frontend.complexFoods.address <| ()
                    , attributes = [ Style.classes.button.overview ]
                    , children = [ text "Complex foods" ]
                    }
                ]
            , div []
                [ Links.linkButton
                    { url = Links.frontendPage model.authorizedAccess.configuration <| Addresses.Frontend.statistics.address <| ()
                    , attributes = [ Style.classes.button.overview ]
                    , children = [ text "Statistics" ]
                    }
                ]
            , div []
                [ Links.linkButton
                    { url = Links.frontendPage model.authorizedAccess.configuration <| Addresses.Frontend.referenceMaps.address <| ()
                    , attributes = [ Style.classes.button.overview ]
                    , children = [ text "Reference maps" ]
                    }
                ]
            , div []
                [ Links.linkButton
                    { url = Links.frontendPage model.authorizedAccess.configuration <| Addresses.Frontend.userSettings.address <| ()
                    , attributes = [ Style.classes.button.overview ]
                    , children = [ text "User settings" ]
                    }
                ]
            ]
