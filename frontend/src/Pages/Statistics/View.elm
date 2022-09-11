module Pages.Statistics.View exposing (view)

import Api.Types.Date exposing (Date)
import Api.Types.NutrientInformation exposing (NutrientInformation)
import Api.Types.NutrientUnit as NutrientUnit exposing (NutrientUnit)
import Html exposing (Html, button, div, input, label, td, text, thead, tr)
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
            (thead []
                [ tr []
                    [ td [] [ label [] [ text "Name" ] ]
                    , td [] [ label [] [ text "Total amount" ] ]
                    , td [] [ label [] [ text "Unit" ] ]
                    , td [] [ label [] [ text "Daily average amount" ] ]
                    , td [] [ label [] [ text "Unit" ] ]
                    ]
                ]
                :: List.map nutrientInformationLine model.stats.nutrients
            )
        , div [ id "meals" ]
            []
        ]


nutrientInformationLine : NutrientInformation -> Html Page.Msg
nutrientInformationLine nutrientInformation =
    let
        nutrientUnitString =
            NutrientUnit.toString <| nutrientInformation.unit
    in
    tr [ id "nutrientInformationLine" ]
        [ td [] [ text <| nutrientInformation.name ]
        , td [] [ text <| String.fromFloat <| nutrientInformation.amounts.total ]
        , td [] [ text <| nutrientUnitString ]
        , td [] [ text <| String.fromFloat <| nutrientInformation.amounts.dailyAverage ]
        , td [] [ text <| nutrientUnitString ]
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
