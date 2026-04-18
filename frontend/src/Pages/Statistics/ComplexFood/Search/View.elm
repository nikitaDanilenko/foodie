module Pages.Statistics.ComplexFood.Search.View exposing (view)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Types.ComplexFood exposing (ComplexFood)
import Html exposing (Html, div, label, table, tbody, td, text, th, thead, tr)
import Monocle.Compose as Compose
import Pages.Statistics.ComplexFood.Search.Page as Page
import Pages.Statistics.ComplexFood.Search.Pagination as Pagination
import Pages.Statistics.StatisticsView as StatisticsView
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.NavigationUtil as NavigationUtil
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
            { currentPage = Just StatisticsVariant.ComplexFood
            }
        <|
            let
                filterOn =
                    SearchUtil.search main.complexFoodsSearchString

                viewComplexFoods =
                    main.complexFoods
                        |> List.filter
                            (\v ->
                                filterOn v.name
                                    || filterOn (v.description |> Maybe.withDefault "")
                            )
                        |> List.sortBy .name
                        |> ViewUtil.paginate
                            { pagination =
                                Page.lenses.main.pagination
                                    |> Compose.lensWithLens Pagination.lenses.complexFoods
                            }
                            main
            in
            div [ Style.ids.statistics.complexFood ]
                [ div []
                    [ HtmlUtil.searchAreaWith
                        { msg = Page.SetSearchString
                        , searchString = main.complexFoodsSearchString
                        }
                    , table [ Style.classes.elementsWithControlsTable ]
                        [ thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [] [ label [] [ text "Name" ] ]
                                , th [] []
                                , th [] []
                                ]
                            ]
                        , tbody []
                            (viewComplexFoods
                                |> Paginate.page
                                |> List.map viewComplexFoodLine
                            )
                        ]
                    , div [ Style.classes.pagination ]
                        [ ViewUtil.pagerButtons
                            { msg =
                                PaginationSettings.updateCurrentPage
                                    { pagination = Page.lenses.main.pagination
                                    , items = Pagination.lenses.complexFoods
                                    }
                                    main
                                    >> Page.SetComplexFoodsPagination
                            , elements = viewComplexFoods
                            }
                        ]
                    ]
                ]


viewComplexFoodLine : ComplexFood -> Html Page.LogicMsg
viewComplexFoodLine complexFood =
    tr [ Style.classes.editing ]
        [ td [ Style.classes.editable ]
            [ label [] [ text complexFood.name ] ]
        , td [ Style.classes.controls ]
            [ NavigationUtil.complexFoodNutrientLinkButton complexFood.recipeId ]
        , td [ Style.classes.controls ]
            [ NavigationUtil.recipeEditorLinkButton complexFood.recipeId ]
        ]
