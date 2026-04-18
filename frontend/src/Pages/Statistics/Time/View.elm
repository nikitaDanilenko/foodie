module Pages.Statistics.Time.View exposing (view)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Types.Date exposing (Date)
import Api.Types.Meal exposing (Meal)
import Api.Types.Profile exposing (Profile)
import Basics.Extra exposing (flip)
import Html exposing (Html, button, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (disabled, type_, value)
import Html.Events exposing (onClick, onInput)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Statistics.StatisticsView as StatisticsView
import Pages.Statistics.Time.Page as Page
import Pages.Statistics.Time.Pagination as Pagination
import Pages.Util.DateUtil as DateUtil
import Pages.Util.Links as Links
import Pages.Util.NavigationUtil as NavigationUtil
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate
import Paginate
import Parser
import Util.MaybeUtil as MaybeUtil
import Uuid


view : Page.Model -> Html Page.Msg
view =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }


viewMain : Page.Main -> Html Page.LogicMsg
viewMain main =
    let
        viewMeals =
            main.stats.meals
                |> List.sortBy (.date >> DateUtil.toString)
                |> List.reverse
                |> ViewUtil.paginate
                    { pagination = Page.lenses.main.pagination |> Compose.lensWithLens Pagination.lenses.meals
                    }
                    main

        weightRow =
            case main.status of
                Page.Display ->
                    [ div [ Style.classes.elements ]
                        [ label
                            []
                            [ text <| (++) "Weight of ingredients: " <| flip (++) "g" <| StatisticsView.displayFloat <| .weightInGrams <| main.stats ]
                        ]
                    ]

                _ ->
                    []

        stats =
            case ( main.status, main.selectedProfile ) of
                ( Page.Display, Just profile ) ->
                    StatisticsView.statisticsTable
                        { onSearchStringChange = Page.SetNutrientsSearchString
                        , searchStringOf = .statisticsEvaluation >> .nutrientsSearchString
                        , infoListOf = .stats >> .nutrients
                        , amountOf = .amounts >> .values >> Maybe.map .total
                        , dailyAmountOf = .amounts >> .values >> Maybe.map .dailyAverage
                        , showDailyAmount = True
                        , completenessFraction =
                            Just
                                { definedValues = .amounts >> .numberOfDefinedValues
                                , totalValues = .amounts >> .numberOfIngredients
                                }
                        , nutrientBase = .base
                        , referenceTree = .statisticsEvaluation >> .referenceTree
                        , tableLabel = "Nutrients in all meals in the interval"
                        }
                        main
                        ++ [ div [ Style.classes.elements ] [ text "Meals" ]
                           , div [ Style.classes.info, Style.classes.meals ]
                                [ table [ Style.classes.elementsWithControlsTable, Style.classes.mealEditTable ]
                                    [ thead []
                                        [ tr []
                                            [ th [] [ label [] [ text "Date" ] ]
                                            , th [] [ label [] [ text "Time" ] ]
                                            , th [] [ label [] [ text "Profile" ] ]
                                            , th [] [ label [] [ text "Name" ] ]
                                            , th [] []
                                            , th [] []
                                            ]
                                        ]
                                    , tbody []
                                        (viewMeals
                                            |> Paginate.page
                                            |> List.map (mealLine profile)
                                        )
                                    ]
                                , div [ Style.classes.pagination ]
                                    [ ViewUtil.pagerButtons
                                        { msg =
                                            PaginationSettings.updateCurrentPage
                                                { pagination = Page.lenses.main.pagination
                                                , items = Pagination.lenses.meals
                                                }
                                                main
                                                >> Page.SetPagination
                                        , elements = viewMeals
                                        }
                                    ]
                                ]
                           ]

                _ ->
                    []
    in
    ViewUtil.viewMainWith
        { currentPage = Just ViewUtil.Statistics
        , showNavigation = True
        }
    <|
        StatisticsView.withNavigationBar
            { currentPage = Just StatisticsVariant.Time
            }
        <|
            div [ Style.ids.statistics.time ]
                (div []
                    [ table [ Style.classes.intervalSelection, Style.classes.elementsWithControlsTable ]
                        [ thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [] [ text "From" ]
                                , th [] [ text "To" ]
                                , th [] [ text "Profile" ]
                                , th [] []
                                , th [] []
                                ]
                            ]
                        , tbody []
                            [ tr []
                                [ td [ Style.classes.editable, Style.classes.date ] [ dateInput main Page.SetFromDate Page.lenses.main.from ]
                                , td [ Style.classes.editable, Style.classes.date ] [ dateInput main Page.SetToDate Page.lenses.main.to ]
                                , td [ Style.classes.editable ]
                                    (StatisticsView.profileSelection
                                        { onProfileSelection = Page.SelectProfile
                                        , profile = .selectedProfile
                                        , profiles = .profiles
                                        }
                                        main
                                    )
                                , td [ Style.classes.controls ]
                                    [ button
                                        ([ MaybeUtil.defined <| Style.classes.button.select
                                         , MaybeUtil.optional (Maybe.Extra.isJust main.selectedProfile) <| onClick Page.FetchStats
                                         , MaybeUtil.defined <| disabled <| Maybe.Extra.isNothing main.selectedProfile
                                         ]
                                            |> Maybe.Extra.values
                                        )
                                        [ text "Compute" ]
                                    ]
                                , td [ Style.classes.controls ]
                                    ([ Links.loadingSymbol ] |> List.filter (always (main.status == Page.Fetch)))
                                ]
                            ]
                        ]
                    ]
                    :: StatisticsView.referenceMapSelection
                        { onReferenceMapSelection = Maybe.andThen Uuid.fromString >> Page.SelectReferenceMap
                        , referenceTrees = .statisticsEvaluation >> .referenceTrees
                        , referenceTree = .statisticsEvaluation >> .referenceTree
                        }
                        main
                    ++ weightRow
                    ++ stats
                )


mealLine : Profile -> Meal -> Html Page.LogicMsg
mealLine profile meal =
    tr [ Style.classes.editLine ]
        [ td [ Style.classes.editable, Style.classes.date ] [ text <| DateUtil.dateToPrettyString <| meal.date.date ]
        , td [ Style.classes.editable, Style.classes.time ] [ text <| Maybe.Extra.unwrap "" DateUtil.timeToString <| meal.date.time ]
        , td [ Style.classes.editable ] [ text <| profile.name ]
        , td [ Style.classes.editable ] [ text <| Maybe.withDefault "" <| meal.name ]
        , td [ Style.classes.controls ]
            [ NavigationUtil.mealNutrientsLinkButton profile.id meal.id ]
        , td [ Style.classes.controls ]
            [ NavigationUtil.mealEditorLinkButton profile.id meal.id ]
        ]


dateInput : Page.Main -> (Maybe Date -> c) -> Lens Page.Main (Maybe Date) -> Html c
dateInput model mkCmd lens =
    input
        [ type_ "date"
        , value <| Maybe.Extra.unwrap "" DateUtil.dateToString <| lens.get <| model
        , onInput
            (Parser.run DateUtil.dateParser
                >> Result.toMaybe
                >> mkCmd
            )
        , Style.classes.date
        ]
        []
