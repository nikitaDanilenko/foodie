module Pages.Statistics.ComplexFood.Select.View exposing (view)

import Basics.Extra exposing (flip)
import Html exposing (Html, div, label, table, td, text, tr)
import Maybe.Extra
import Pages.Statistics.ComplexFood.Select.Page as Page
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
            let
                millilitresLine =
                    main.complexFood.amountMilliLitres
                        |> Maybe.Extra.unwrap []
                            (\amount ->
                                [ tr []
                                    [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Volume (set)" ] ]
                                    , td [] [ label [] [ text <| flip (++) "ml" <| StatisticsView.displayFloat <| amount ] ]
                                    ]
                                ]
                            )
            in
            div [ Style.classes.partialStatistics ]
                (div []
                    [ table [ Style.classes.info ]
                        ([ tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Complex food" ] ]
                            , td [] [ label [] [ text <| .name <| main.complexFood ] ]
                            ]
                         , tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Description" ] ]
                            , td [] [ label [] [ text <| Maybe.withDefault "" <| .description <| main.complexFood ] ]
                            ]
                         , tr []
                            [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Weight (set)" ] ]
                            , td [] [ label [] [ text <| flip (++) "g" <| StatisticsView.displayFloat <| .amountGrams <| main.complexFood ] ]
                            ]
                         ]
                            ++ millilitresLine
                        )
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
                        , tableLabel = "Nutrients per 100g"
                        }
                        main
                )
