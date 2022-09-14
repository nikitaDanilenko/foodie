module Pages.Statistics.View exposing (view)

import Api.Types.Date exposing (Date)
import Api.Types.Meal exposing (Meal)
import Api.Types.NutrientInformation exposing (NutrientInformation)
import Api.Types.NutrientUnit as NutrientUnit exposing (NutrientUnit)
import FormatNumber
import FormatNumber.Locales
import Html exposing (Html, button, div, input, label, span, td, text, thead, tr)
import Html.Attributes exposing (class, id, type_, value)
import Html.Events exposing (onClick, onInput)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.Statistics.Page as Page
import Pages.Util.DateUtil as DateUtil
import Parser


view : Page.Model -> Html Page.Msg
view model =
    div [ id "statistics" ]
        [ div [ id "intervalSelection" ]
            [ label [] [ text "From" ]
            , dateInput model Page.SetFromDate Page.lenses.from
            , label [] [ text "To" ]
            , dateInput model Page.SetToDate Page.lenses.to
            , button
                [ class "button", onClick Page.FetchStats ]
                [ text "Compute" ]
            ]
        , div [ id "nutrientInformation" ]
            (div [ id "nutrientInformationHeader" ] [ text "Nutrients" ]
                :: thead []
                    [ tr []
                        [ td [] [ label [] [ text "Name" ] ]
                        , td [] [ label [] [ text "Total amount" ] ]
                        , td [] [ label [] [ text "Daily average amount" ] ]
                        , td [] [ label [] [ text "Reference daily average amount" ] ]
                        , td [] [ label [] [ text "Actual factor" ] ]
                        , td [] [ label [] [ text "Unit" ] ]
                        ]
                    ]
                :: List.map nutrientInformationLine model.stats.nutrients
            )
        , div [ id "meals" ]
            (div [ id "mealsHeader" ] [ text "Meals" ]
                :: thead []
                    [ tr []
                        [ td [] [ label [] [ text "Name" ] ]
                        , td [] [ label [] [ text "Description" ] ]
                        ]
                    ]
                :: (model.stats.meals
                        |> List.sortBy (.date >> DateUtil.toString)
                        |> List.reverse
                        |> List.map mealLine
                   )
            )
        ]


nutrientInformationLine : NutrientInformation -> Html Page.Msg
nutrientInformationLine nutrientInformation =
    let
        nutrientUnitString =
            NutrientUnit.toString <| nutrientInformation.unit
    in
    tr [ id "nutrientInformationLine" ]
        [ td []
            [ div [ class "tooltip" ]
                [ text <| nutrientInformation.symbol
                , span [ class "tooltipText" ] [ text <| nutrientInformation.name ]
                ]
            ]
        , td [] [ text <| displayFloat <| nutrientInformation.amounts.total ]
        , td [] [ text <| displayFloat <| nutrientInformation.amounts.dailyAverage ]
        , td [] [ text <| Maybe.Extra.unwrap "" displayFloat <| nutrientInformation.amounts.referenceDailyAverage ]
        , td []
            [ text <|   Maybe.Extra.unwrap "" ((\v -> v ++ "%") << displayFloat) <|
                    referenceFactor
                        { actualValue = nutrientInformation.amounts.dailyAverage
                        , referenceValue = nutrientInformation.amounts.referenceDailyAverage
                        }
            ]
        , td [] [ text <| nutrientUnitString ]
        ]


mealLine : Meal -> Html Page.Msg
mealLine meal =
    tr [ id "mealLine" ]
        [ td [] [ label [] [ text <| DateUtil.toString <| meal.date ] ]
        , td [] [ label [] [ text <| Maybe.withDefault "" <| meal.name ] ]
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
                    * (if vs.actualValue == 0 then
                        1

                       else
                        vs.actualValue / r
                      )
            )
