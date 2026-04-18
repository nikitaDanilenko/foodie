module Pages.Statistics.Meal.Search.View exposing (view)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Types.Meal exposing (Meal)
import Api.Types.Profile exposing (Profile)
import Html exposing (Html, div, table, tbody, td, text, th, thead, tr)
import Maybe.Extra
import Monocle.Compose as Compose
import Pages.Statistics.Meal.Search.Page as Page
import Pages.Statistics.Meal.Search.Pagination as Pagination
import Pages.Statistics.StatisticsView as StatisticsView
import Pages.Util.DateUtil as DateUtil
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
            { currentPage = Just StatisticsVariant.Meal
            }
        <|
            let
                filterOn =
                    SearchUtil.search main.mealsSearchString

                viewMeals =
                    main.meals
                        |> List.filter
                            (\v ->
                                filterOn (v.name |> Maybe.withDefault "")
                                    || filterOn (v.date |> DateUtil.toPrettyString)
                            )
                        |> List.sortBy (.date >> DateUtil.toPrettyString)
                        |> List.reverse
                        |> ViewUtil.paginate
                            { pagination =
                                Page.lenses.main.pagination
                                    |> Compose.lensWithLens Pagination.lenses.meals
                            }
                            main
            in
            div [ Style.ids.statistics.meal ]
                [ div []
                    [ HtmlUtil.searchAreaWith
                        { msg = Page.SetSearchString
                        , searchString = main.mealsSearchString
                        }
                    , table [ Style.classes.elementsWithControlsTable ]
                        [ thead []
                            [ tr [ Style.classes.tableHeader, Style.classes.mealEditTable ]
                                [ th [] [ text "Date" ]
                                , th [] [ text "Time" ]
                                , th [] [ text "Profile" ]
                                , th [] [ text "Name" ]
                                , th [] []
                                , th [] []
                                ]
                            ]
                        , tbody []
                            (viewMeals
                                |> Paginate.page
                                |> List.map (viewMealLine main.profile)
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
                                    >> Page.SetMealsPagination
                            , elements = viewMeals
                            }
                        ]
                    ]
                ]


viewMealLine : Profile -> Meal -> Html Page.LogicMsg
viewMealLine profile meal =
    tr [ Style.classes.editLine ]
        [ td [ Style.classes.editable ]
            [ text <| DateUtil.dateToPrettyString <| meal.date.date ]
        , td [ Style.classes.editable ]
            [ text <| Maybe.Extra.unwrap "" DateUtil.timeToString <| meal.date.time ]
        , td [ Style.classes.editable ]
            [ text <| profile.name ]
        , td [ Style.classes.editable ]
            [ text <| Maybe.withDefault "" <| meal.name ]
        , td [ Style.classes.controls ]
            [ NavigationUtil.mealNutrientsLinkButton profile.id meal.id ]
        , td [ Style.classes.controls ]
            [ NavigationUtil.mealEditorLinkButton profile.id meal.id ]
        ]
