module Pages.Meals.View exposing (view)

import Api.Lenses.MealUpdateLens as MealUpdateLens
import Api.Lenses.SimpleDateLens as SimpleDateLens
import Api.Types.Meal exposing (Meal)
import Api.Types.MealUpdate exposing (MealUpdate)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Either
import Html exposing (Html, button, div, input, label, td, text, thead, tr)
import Html.Attributes exposing (class, id, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Pages.Meals.Model
import Pages.Meals.Msg exposing (Msg(..))
import Pages.Util.DateUtil as DateUtil
import Pages.Util.Links as Links
import Parser
import Url.Builder


view : Pages.Meals.Model.Model -> Html Pages.Meals.Msg.Msg
view model =
    let
        viewEditMeals =
            List.map
                (Either.unpack
                    (editOrDeleteMealLine model.configuration)
                    (\e -> e.update |> editMealLine)
                )
    in
    div [ id "addMealView" ]
        (div [ id "addMeal" ] [ button [ class "button", onClick CreateMeal ] [ text "New meal" ] ]
            :: thead []
                [ tr []
                    [ td [] [ label [] [ text "Name" ] ]
                    , td [] [ label [] [ text "Description" ] ]
                    ]
                ]
            :: viewEditMeals model.meals
        )


editOrDeleteMealLine : Configuration -> Meal -> Html Msg
editOrDeleteMealLine configuration meal =
    tr [ id "editingMeal" ]
        [ td [] [ label [] [ text <| DateUtil.toString <| meal.date ] ]
        , td [] [ label [] [ text <| Maybe.withDefault "" <| meal.name ] ]
        , td [] [ button [ class "button", onClick (EnterEditMeal meal.id) ] [ text "Edit" ] ]
        , td []
            [ Links.linkButton
                { url =
                    Url.Builder.relative
                        [ configuration.mainPageURL
                        , "#"
                        , "meal-entry-editor"
                        , meal.id
                        ]
                        []
                , attributes = [ class "button" ]
                , children = [ text "Edit meal entries" ]
                , isDisabled = False
                }
            ]
        , td [] [ button [ class "button", onClick (DeleteMeal meal.id) ] [ text "Delete" ] ]
        ]


editMealLine : MealUpdate -> Html Msg
editMealLine mealUpdate =
    let
        saveMsg =
            SaveMealEdit mealUpdate.id
    in
    div [ class "mealLine" ]
        [ div [ class "mealDateArea" ]
            [ label [] [ text "Date" ]
            , div [ class "date" ]
                [ input
                    [ type_ "date"
                    , value <| DateUtil.dateToString <| mealUpdate.date.date
                    , onInput
                        (Parser.run DateUtil.dateParser
                            >> Result.withDefault mealUpdate.date.date
                            >> flip
                                (MealUpdateLens.date
                                    |> Compose.lensWithLens SimpleDateLens.date
                                ).set
                                mealUpdate
                            >> UpdateMeal
                        )
                    , onEnter saveMsg
                    ]
                    []
                ]
            , div [ class "time" ]
                [ input
                    [ type_ "time"
                    , value <| Maybe.Extra.unwrap "" DateUtil.timeToString <| mealUpdate.date.time
                    , onInput
                        (Parser.run DateUtil.timeParser
                            >> Result.toMaybe
                            >> flip
                                (MealUpdateLens.date
                                    |> Compose.lensWithLens SimpleDateLens.time
                                ).set
                                mealUpdate
                            >> UpdateMeal
                        )
                    , onEnter saveMsg
                    ]
                    []
                ]
            ]
        , div [ class "name" ]
            [ label [] [ text "Name" ]
            , input
                [ value <| Maybe.withDefault "" mealUpdate.name
                , onInput
                    (Just
                        >> Maybe.Extra.filter (String.isEmpty >> not)
                        >> flip MealUpdateLens.name.set mealUpdate
                        >> UpdateMeal
                    )
                , onEnter saveMsg
                ]
                []
            ]
        , button [ class "button", onClick (SaveMealEdit mealUpdate.id) ]
            [ text "Save" ]
        , button [ class "button", onClick (ExitEditMealAt mealUpdate.id) ]
            [ text "Cancel" ]
        ]
