module Pages.Statistics.View exposing (view)

import Api.Types.Date exposing (Date)
import Api.Types.Meal exposing (Meal)
import Api.Types.NutrientInformation exposing (NutrientInformation)
import Api.Types.NutrientUnit as NutrientUnit exposing (NutrientUnit)
import FormatNumber
import FormatNumber.Locales
import Html exposing (Html, button, col, colgroup, div, input, label, span, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, colspan, id, scope, type_, value)
import Html.Events exposing (onClick, onInput)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.Statistics.Page as Page
import Pages.Statistics.Status as Status
import Pages.Util.DateUtil as DateUtil
import Pages.Util.ViewUtil as ViewUtil
import Parser


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = .initialization
        , flagsWithJWT = .flagsWithJWT
        }
        model
    <|
        div [ id "statistics" ]
            [ div []
                [ table [ class "intervalSelection" ]
                    [ colgroup []
                        [ col [] []
                        , col [] []
                        , col [] []
                        , col [] []
                        ]
                    , thead []
                        [ tr [ class "tableHeader" ]
                            [ th [ scope "col" ] [ label [] [ text "From" ] ]
                            , th [ scope "col" ] [ label [] [ text "To" ] ]
                            , th [ colspan 2, scope "col", class "controlsGroup" ] []
                            ]
                        ]
                    , tbody []
                        [ tr []
                            [ td [ class "editable", class "date" ] [ dateInput model Page.SetFromDate Page.lenses.from ]
                            , td [ class "editable", class "date" ] [ dateInput model Page.SetToDate Page.lenses.to ]
                            , td [ class "controls" ]
                                [ button
                                    [ class "selectButton", onClick Page.FetchStats ]
                                    [ text "Compute" ]
                                ]
                            , td [ class "controls" ] []
                            ]
                        ]
                    ]
                ]
            , div [ class "elements" ] [ text "Nutrients" ]
            , div [ class "information", class "nutrients" ]
                [ table []
                    [ thead []
                        [ tr [ class "tableHeader" ]
                            [ th [] [ label [] [ text "Name" ] ]
                            , th [ class "numberLabel" ] [ label [] [ text "Total" ] ]
                            , th [ class "numberLabel" ] [ label [] [ text "Daily average" ] ]
                            , th [ class "numberLabel" ] [ label [] [ text "Reference daily average" ] ]
                            , th [ class "numberLabel" ] [ label [] [ text "Unit" ] ]
                            , th [ class "numberLabel" ] [ label [] [ text "Percentage" ] ]
                            ]
                        ]
                    , tbody [] (List.map nutrientInformationLine model.stats.nutrients)
                    ]
                ]
            , div [ class "elements" ] [ text "Meals" ]
            , div [ class "information", class "meals" ]
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
                    [ class <|
                        if percent > 100 then
                            "high"

                        else if percent == 100 then
                            "exact"

                        else
                            "low"
                    ]
                )
                factor
    in
    tr [ class "editLine" ]
        [ td []
            [ div [ class "tooltip" ]
                [ text <| nutrientInformation.symbol
                , span [ class "tooltipText" ] [ text <| nutrientInformation.name ]
                ]
            ]
        , td [ class "numberCell" ] [ label [] [ text <| displayFloat <| nutrientInformation.amounts.total ] ]
        , td [ class "numberCell" ] [ label [] [ text <| displayFloat <| nutrientInformation.amounts.dailyAverage ] ]
        , td [ class "numberCell" ] [ label [] [ text <| Maybe.Extra.unwrap "" displayFloat <| nutrientInformation.amounts.referenceDailyAverage ] ]
        , td [ class "numberCell" ] [ label [] [ text <| NutrientUnit.toString <| nutrientInformation.unit ] ]
        , td [ class "numberCell" ]
            [ label factorStyle
                [ text <|
                    Maybe.Extra.unwrap "" ((\v -> v ++ "%") << displayFloat) <|
                        factor
                ]
            ]
        ]


mealLine : Meal -> Html Page.Msg
mealLine meal =
    tr [ class "editLine" ]
        [ td [ class "editable", class "date" ] [ label [] [ text <| DateUtil.dateToString <| meal.date.date ] ]
        , td [ class "editable", class "time" ] [ label [] [ text <| Maybe.Extra.unwrap "" DateUtil.timeToString <| meal.date.time ] ]
        , td [ class "editable" ] [ label [] [ text <| Maybe.withDefault "" <| meal.name ] ]
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
        , class "date"
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
