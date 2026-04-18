module Pages.Statistics.Food.Select.View exposing (view)

import Html exposing (Html, div, label, table, td, text, tr)
import Pages.Statistics.Food.Select.Page as Page
import Pages.Statistics.StatisticsView as StatisticsView
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate
import Uuid


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
        StatisticsView.withNavigationBar
            { currentPage = Nothing
            }
        <|
            div [ Style.classes.partialStatistics ]
                (div []
                    [ table [ Style.classes.info ]
                        [ tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Food" ] ]
                            , td [] [ label [] [ text <| .name <| main.foodInfo ] ]
                            ]
                        ]
                    ]
                    :: StatisticsView.referenceMapSelection
                        { onReferenceMapSelection = Maybe.andThen Uuid.fromString >> Page.SelectReferenceMap
                        , referenceTrees = .statisticsEvaluation >> .referenceTrees
                        , referenceTree = .statisticsEvaluation >> .referenceTree
                        }
                        main
                    ++ StatisticsView.statisticsTable
                        { onSearchStringChange = Page.SetNutrientsSearchString
                        , searchStringOf = .statisticsEvaluation >> .nutrientsSearchString
                        , infoListOf = .foodStats >> .nutrients
                        , amountOf = .amount
                        , dailyAmountOf = .amount
                        , showDailyAmount = False
                        , completenessFraction = Nothing
                        , nutrientBase = .base
                        , referenceTree = .statisticsEvaluation >> .referenceTree
                        , tableLabel = "Nutrients per 100g"
                        }
                        main
                )
