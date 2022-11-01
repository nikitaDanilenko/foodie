module Pages.Statistics.View exposing (view)

import Api.Auxiliary exposing (NutrientCode)
import Api.Types.Date exposing (Date)
import Api.Types.Meal exposing (Meal)
import Api.Types.NutrientInformation exposing (NutrientInformation)
import Api.Types.NutrientUnit as NutrientUnit exposing (NutrientUnit)
import Dict exposing (Dict)
import Dropdown exposing (dropdown)
import FormatNumber
import FormatNumber.Locales
import Html exposing (Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, scope, type_, value)
import Html.Events exposing (onClick, onInput)
import List.Extra
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Statistics.Page as Page
import Pages.Statistics.Pagination as Pagination
import Pages.Util.DateUtil as DateUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Paginate
import Parser
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view model =
    let
        viewMeals =
            model.stats.meals
                |> List.sortBy (.date >> DateUtil.toString)
                |> List.reverse
                |> ViewUtil.paginate
                    { pagination = Page.lenses.pagination |> Compose.lensWithLens Pagination.lenses.meals
                    }
                    model
    in
    ViewUtil.viewWithErrorHandling
        { isFinished = always True
        , initialization = .initialization
        , configuration = .authorizedAccess >> .configuration
        , jwt = .authorizedAccess >> .jwt >> Just
        , currentPage = Just ViewUtil.Statistics
        , showNavigation = True
        }
        model
    <|
        let
            viewNutrients =
                model.stats.nutrients
                    |> List.filter (\nutrient -> [ nutrient.name, nutrient.symbol ] |> List.Extra.find (SearchUtil.search model.nutrientsSearchString) |> Maybe.Extra.isJust)
        in
        div [ Style.ids.statistics ]
            [ div []
                [ table [ Style.classes.intervalSelection ]
                    [ colgroup []
                        [ col [] []
                        , col [] []
                        , col [] []
                        , col [] []
                        ]
                    , thead []
                        [ tr [ Style.classes.tableHeader ]
                            [ th [ scope "col" ] [ label [] [ text "From" ] ]
                            , th [ scope "col" ] [ label [] [ text "To" ] ]
                            , th [ colspan 2, scope "col", Style.classes.controlsGroup ] []
                            ]
                        ]
                    , tbody []
                        [ tr []
                            [ td [ Style.classes.editable, Style.classes.date ] [ dateInput model Page.SetFromDate Page.lenses.from ]
                            , td [ Style.classes.editable, Style.classes.date ] [ dateInput model Page.SetToDate Page.lenses.to ]
                            , td [ Style.classes.controls ]
                                [ button
                                    [ Style.classes.button.select, onClick Page.FetchStats ]
                                    [ text "Compute" ]
                                ]
                            , td [ Style.classes.controls ]
                                (if model.fetching then
                                    [ Links.loadingSymbol ]

                                 else
                                    []
                                )
                            ]
                        ]
                    ]
                ]
            , div [ Style.classes.elements ] [ text "Reference map" ]
            , div [ Style.classes.info ]
                [ dropdown
                    { items =
                        model.referenceTrees
                            |> Dict.toList
                            |> List.sortBy (Tuple.second >> .map >> .name)
                            |> List.map
                                (\( referenceMapId, referenceTree ) ->
                                    { value = referenceMapId
                                    , text = referenceTree.map.name
                                    , enabled = True
                                    }
                                )
                    , emptyItem =
                        Just
                            { value = ""
                            , text = ""
                            , enabled = True
                            }
                    , onChange = Page.SelectReferenceMap
                    }
                    []
                    (model.referenceTree |> Maybe.map (.map >> .id))
                ]
            , div [ Style.classes.elements ] [ text "Nutrients" ]
            , div [ Style.classes.info, Style.classes.nutrients ]
                [ HtmlUtil.searchAreaWith
                    { msg = Page.SetNutrientsSearchString
                    , searchString = model.nutrientsSearchString
                    }
                , table []
                    [ thead []
                        [ tr [ Style.classes.tableHeader ]
                            [ th [] [ label [] [ text "Name" ] ]
                            , th [ Style.classes.numberLabel ] [ label [] [ text "Total" ] ]
                            , th [ Style.classes.numberLabel ] [ label [] [ text "Daily average" ] ]
                            , th [ Style.classes.numberLabel ] [ label [] [ text "Reference daily average" ] ]
                            , th [ Style.classes.numberLabel ] [ label [] [ text "Unit" ] ]
                            , th [ Style.classes.numberLabel ] [ label [] [ text "Percentage" ] ]
                            ]
                        ]
                    , tbody [] (List.map (model.referenceTree |> Maybe.Extra.unwrap Dict.empty .values |> nutrientInformationLine) viewNutrients)
                    ]
                ]
            , div [ Style.classes.elements ] [ text "Meals" ]
            , div [ Style.classes.info, Style.classes.meals ]
                [ table []
                    [ thead []
                        [ tr []
                            [ th [] [ label [] [ text "Date" ] ]
                            , th [] [ label [] [ text "Time" ] ]
                            , th [] [ label [] [ text "Name" ] ]
                            , th [] [ label [] [ text "Description" ] ]
                            ]
                        ]
                    , tbody []
                        (viewMeals
                            |> Paginate.page
                            |> List.map mealLine
                        )
                    ]
                , div [ Style.classes.pagination ]
                    [ ViewUtil.pagerButtons
                        { msg =
                            PaginationSettings.updateCurrentPage
                                { pagination = Page.lenses.pagination
                                , items = Pagination.lenses.meals
                                }
                                model
                                >> Page.SetPagination
                        , elements = viewMeals
                        }
                    ]
                ]
            ]


nutrientInformationLine : Dict NutrientCode Float -> NutrientInformation -> Html Page.Msg
nutrientInformationLine referenceValues nutrientInformation =
    let
        referenceValue =
            Dict.get nutrientInformation.nutrientCode referenceValues

        factor =
            referenceFactor
                { actualValue = nutrientInformation.amounts.dailyAverage
                , referenceValue = referenceValue
                }

        factorStyle =
            Maybe.Extra.unwrap []
                (\percent ->
                    [ if percent > 100 then
                        Style.classes.rating.high

                      else if percent == 100 then
                        Style.classes.rating.exact

                      else
                        Style.classes.rating.low
                    ]
                )
                factor
    in
    tr [ Style.classes.editLine ]
        [ td [] [ label [] [ text <| nutrientInformation.name ] ]
        , td [ Style.classes.numberCell ] [ label [] [ text <| displayFloat <| nutrientInformation.amounts.total ] ]
        , td [ Style.classes.numberCell ] [ label [] [ text <| displayFloat <| nutrientInformation.amounts.dailyAverage ] ]
        , td [ Style.classes.numberCell ] [ label [] [ text <| Maybe.Extra.unwrap "" displayFloat <| referenceValue ] ]
        , td [ Style.classes.numberCell ] [ label [] [ text <| NutrientUnit.toString <| nutrientInformation.unit ] ]
        , td [ Style.classes.numberCell ]
            [ label factorStyle
                [ text <|
                    Maybe.Extra.unwrap "" ((\v -> v ++ "%") << displayFloat) <|
                        factor
                ]
            ]
        ]


mealLine : Meal -> Html Page.Msg
mealLine meal =
    tr [ Style.classes.editLine ]
        [ td [ Style.classes.editable, Style.classes.date ] [ label [] [ text <| DateUtil.dateToString <| meal.date.date ] ]
        , td [ Style.classes.editable, Style.classes.time ] [ label [] [ text <| Maybe.Extra.unwrap "" DateUtil.timeToString <| meal.date.time ] ]
        , td [ Style.classes.editable ] [ label [] [ text <| Maybe.withDefault "" <| meal.name ] ]
        ]


dateInput : Page.Model -> (Maybe Date -> c) -> Lens Page.Model (Maybe Date) -> Html c
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


displayFloat : Float -> String
displayFloat =
    FormatNumber.format FormatNumber.Locales.frenchLocale


referenceFactor :
    { actualValue : Float
    , referenceValue : Maybe Float
    }
    -> Maybe Float
referenceFactor vs =
    vs.referenceValue
        |> Maybe.Extra.filter (\x -> x > 0)
        |> Maybe.map
            (\r ->
                100
                    * (vs.actualValue / r)
            )
