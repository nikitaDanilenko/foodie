module Pages.Statistics.RecipeOccurrences.ProfileChoice.View exposing (..)

import Addresses.Frontend
import Addresses.StatisticsVariant as StatisticsVariant
import Html exposing (Html)
import Pages.Meals.ProfileChoice.Page as Page
import Pages.Statistics.StatisticsView as StatisticsView
import Pages.Util.ProfileChoice.View
import Pages.Util.ViewUtil as ViewUtil


view : Page.Model -> Html Page.Msg
view model =
    Pages.Util.ProfileChoice.View.viewWith
        { address = Addresses.Frontend.statisticsRecipeOccurrences.address
        , currentPage = ViewUtil.Statistics
        , modifier =
            StatisticsView.withNavigationBar
                { currentPage = Just StatisticsVariant.RecipeOccurrences
                }
        }
        model
