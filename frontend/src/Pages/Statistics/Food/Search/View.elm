module Pages.Statistics.Food.Search.View exposing (view)

import Addresses.Frontend
import Addresses.StatisticsVariant as StatisticsVariant
import Api.Types.Food exposing (Food)
import Html exposing (Html, col, colgroup, div, label, table, tbody, td, text, th, thead, tr)
import Monocle.Compose as Compose
import Pages.Statistics.Food.Search.Page as Page
import Pages.Statistics.Food.Search.Pagination as Pagination
import Pages.Statistics.StatisticsView as StatisticsView
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil exposing (Page(..))
import Pages.View.Tristate as Tristate
import Paginate
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }


viewMain : Page.Main -> Html Page.LogicMsg
viewMain main =
    ViewUtil.viewMainWith
        { currentPage = Just Statistics
        , showNavigation = True
        }
    <|
        StatisticsView.withNavigationBar
            { currentPage = Just StatisticsVariant.Food
            }
        <|
            let
                viewFoods =
                    main.foods
                        |> List.filter (\v -> SearchUtil.search main.foodsSearchString v.name)
                        |> List.sortBy .name
                        |> ViewUtil.paginate
                            { pagination =
                                Page.lenses.main.pagination
                                    |> Compose.lensWithLens Pagination.lenses.foods
                            }
                            main
            in
            div [ Style.ids.statistics.food ]
                [ div []
                    [ HtmlUtil.searchAreaWith
                        { msg = Page.SetSearchString
                        , searchString = main.foodsSearchString
                        }
                    , table [ Style.classes.elementsWithControlsTable ]
                        [ colgroup []
                            [ col [] []
                            , col [] []
                            ]
                        , thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [] [ label [] [ text "Name" ] ]
                                , th [ Style.classes.controlsGroup ] []
                                ]
                            ]
                        , tbody []
                            (viewFoods
                                |> Paginate.page
                                |> List.map viewFoodLine
                            )
                        ]
                    , div [ Style.classes.pagination ]
                        [ ViewUtil.pagerButtons
                            { msg =
                                PaginationSettings.updateCurrentPage
                                    { pagination = Page.lenses.main.pagination
                                    , items = Pagination.lenses.foods
                                    }
                                    main
                                    >> Page.SetFoodsPagination
                            , elements = viewFoods
                            }
                        ]
                    ]
                ]


viewFoodLine : Food -> Html Page.LogicMsg
viewFoodLine food =
    tr [ Style.classes.editing ]
        [ td [ Style.classes.editable ]
            [ label [] [ text food.name ] ]
        , td [ Style.classes.controls ]
            [ Links.linkButton
                { url = Links.frontendPage <| Addresses.Frontend.statisticsFoodSelect.address <| food.id
                , attributes = [ Style.classes.button.nutrients ]
                , children = [ text "Nutrients" ]
                }
            ]
        ]
