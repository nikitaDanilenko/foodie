module Pages.Statistics.Meal.Search.View exposing (view)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Auxiliary exposing (ProfileId)
import Api.Types.Meal exposing (Meal)
import Configuration exposing (Configuration)
import Html exposing (Html, div, label, table, tbody, td, text, th, thead, tr)
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


viewMain : Configuration -> Page.Main -> Html Page.LogicMsg
viewMain configuration main =
    ViewUtil.viewMainWith
        { configuration = configuration
        , jwt = .jwt >> Just
        , currentPage = Just Statistics
        , showNavigation = True
        }
        main
    <|
        StatisticsView.withNavigationBar
            { mainPageURL = configuration.mainPageURL
            , currentPage = Just StatisticsVariant.Meal
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
                                [ th [] [ label [] [ text "Date" ] ]
                                , th [] [ label [] [ text "Time" ] ]
                                , th [] [ label [] [ text "Name" ] ]
                                , th [] []
                                , th [] []
                                ]
                            ]
                        , tbody []
                            (viewMeals
                                |> Paginate.page
                                |> List.map (viewMealLine configuration main.profile.id)
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


viewMealLine : Configuration -> ProfileId -> Meal -> Html Page.LogicMsg
viewMealLine configuration profileId meal =
    tr [ Style.classes.editLine ]
        [ td [ Style.classes.editable ]
            [ label [] [ text <| DateUtil.dateToPrettyString <| meal.date.date ] ]
        , td [ Style.classes.editable ]
            [ label [] [ text <| Maybe.Extra.unwrap "" DateUtil.timeToString <| meal.date.time ] ]
        , td [ Style.classes.editable ]
            [ label [] [ text <| Maybe.withDefault "" <| meal.name ] ]
        , td [ Style.classes.controls ]
            [ NavigationUtil.mealNutrientsLinkButton configuration profileId meal.id ]
        , td [ Style.classes.controls ]
            [ NavigationUtil.mealEditorLinkButton configuration profileId meal.id ]
        ]
