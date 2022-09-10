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
import Pages.Meals.Page as Page
import Pages.Util.DateUtil as DateUtil
import Pages.Util.Links as Links
import Parser
import Url.Builder


view : Page.Model -> Html Page.Msg
view model =
    let
        viewEditMeals =
            List.map
                (Either.unpack
                    (editOrDeleteMealLine model.flagsWithJWT.configuration)
                    (\e -> e.update |> editMealLine)
                )
    in
    div [ id "addMealView" ]
        (div [ id "addMeal" ] [ button [ class "button", onClick Page.CreateMeal ] [ text "New meal" ] ]
            :: thead []
                [ tr []
                    [ td [] [ label [] [ text "Name" ] ]
                    , td [] [ label [] [ text "Description" ] ]
                    ]
                ]
            :: viewEditMeals model.meals
        )


editOrDeleteMealLine : Configuration -> Meal -> Html Page.Msg
editOrDeleteMealLine configuration meal =
    tr [ id "editingMeal" ]
        [ td [] [ label [] [ text <| DateUtil.toString <| meal.date ] ]
        , td [] [ label [] [ text <| Maybe.withDefault "" <| meal.name ] ]
        , td [] [ button [ class "button", onClick (Page.EnterEditMeal meal.id) ] [ text "Edit" ] ]
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
        , td [] [ button [ class "button", onClick (Page.DeleteMeal meal.id) ] [ text "Delete" ] ]
        ]


editMealLine : MealUpdate -> Html Page.Msg
editMealLine mealUpdate =
    let
        saveMsg =
            Page.SaveMealEdit mealUpdate.id
    in
    tr [ id "mealLine" ]
        [ td []
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
                        >> Page.UpdateMeal
                    )
                , onEnter saveMsg
                ]
                []
            , input
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
                        >> Page.UpdateMeal
                    )
                , onEnter saveMsg
                ]
                []
            ]
        , td []
            [ input
                [ value <| Maybe.withDefault "" mealUpdate.name
                , onInput
                    (Just
                        >> Maybe.Extra.filter (String.isEmpty >> not)
                        >> flip MealUpdateLens.name.set mealUpdate
                        >> Page.UpdateMeal
                    )
                , onEnter saveMsg
                ]
                []
            ]
        , td []
            [ button [ class "button", onClick (Page.SaveMealEdit mealUpdate.id) ]
                [ text "Save" ]
            ]
        , td []
            [ button [ class "button", onClick (Page.ExitEditMealAt mealUpdate.id) ]
                [ text "Cancel" ]
            ]
        ]
