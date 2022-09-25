module Pages.Statistics.View exposing (view)

import Api.Types.Date exposing (Date)
import Api.Types.Meal exposing (Meal)
import Api.Types.NutrientInformation exposing (NutrientInformation)
import Api.Types.NutrientUnit as NutrientUnit exposing (NutrientUnit)
import FormatNumber
import FormatNumber.Locales
import Html exposing (Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, scope, type_, value)
import Html.Events exposing (onClick, onInput)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.Statistics.Page as Page
import Pages.Statistics.Status as Status
import Pages.Util.DateUtil as DateUtil
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Parser


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = .initialization
        , flagsWithJWT = .flagsWithJWT
        , currentPage = Just ViewUtil.Statistics
        }
        model
    <|
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
                            , td [ Style.classes.controls ] []
                            ]
                        ]
                    ]
                ]
            , div [ Style.classes.elements ] [ text "Nutrients" ]
            , div [ Style.classes.info, Style.classes.nutrients ]
                [ table []
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
                    , tbody [] (List.map nutrientInformationLine model.stats.nutrients)
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
                        (model.stats.meals
                            |> List.sortBy (.date >> DateUtil.toString)
                            |> List.reverse
                            |> List.map mealLine
                        )
                    ]
                ]
            ]


nutrientInformationLine : NutrientInformation -> Html Page.Msg
nutrientInformationLine nutrientInformation =
    let
        factor =
            referenceFactor
                { actualValue = nutrientInformation.amounts.dailyAverage
                , referenceValue = nutrientInformation.amounts.referenceDailyAverage
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
        , td [ Style.classes.numberCell ] [ label [] [ text <| Maybe.Extra.unwrap "" displayFloat <| nutrientInformation.amounts.referenceDailyAverage ] ]
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
