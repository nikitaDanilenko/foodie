module Pages.Statistics.Meal.Select.View exposing (view)

import Basics.Extra exposing (flip)
import Html exposing (Html, div, label, table, td, text, tr)
import Maybe.Extra
import Pages.Statistics.Meal.Select.Page as Page
import Pages.Statistics.StatisticsView as StatisticsView
import Pages.Util.DateUtil as DateUtil
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
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Date" ] ]
                            , td [] [ label [] [ text <| (DateUtil.dateToPrettyString << .date << .date) <| main.meal ] ]
                            ]
                        , tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Time" ] ]
                            , td [] [ label [] [ text <| (Maybe.Extra.unwrap "" DateUtil.timeToString << .time << .date) <| main.meal ] ]
                            ]
                        , tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Profile" ] ]
                            , td [] [ label [] [ text <| main.profile.name ] ]
                            ]
                        , tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Name" ] ]
                            , td [] [ label [] [ text <| Maybe.withDefault "" <| .name <| main.meal ] ]
                            ]
                        , tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Weight of ingredients" ] ]
                            , td [] [ label [] [ text <| flip (++) "g" <| StatisticsView.displayFloat <| .weightInGrams <| main.mealStats ] ]
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
                        , infoListOf = .mealStats >> .nutrients
                        , amountOf = .amount >> .value
                        , dailyAmountOf = .amount >> .value
                        , showDailyAmount = False
                        , completenessFraction =
                            Just
                                { definedValues = .amount >> .numberOfDefinedValues
                                , totalValues = .amount >> .numberOfIngredients
                                }
                        , nutrientBase = .base
                        , referenceTree = .statisticsEvaluation >> .referenceTree
                        , tableLabel = "Nutrients in the meal"
                        }
                        main
                )
