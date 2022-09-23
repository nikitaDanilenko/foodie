module Pages.Meals.View exposing (view)

import Api.Lenses.MealUpdateLens as MealUpdateLens
import Api.Lenses.SimpleDateLens as SimpleDateLens
import Api.Types.Meal exposing (Meal)
import Api.Types.MealUpdate exposing (MealUpdate)
import Api.Types.SimpleDate exposing (SimpleDate)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Dict
import Either exposing (Either(..))
import Html exposing (Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, colspan, id, scope, type_, value)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Meals.MealCreationClientInput as MealCreationClientInput exposing (MealCreationClientInput)
import Pages.Meals.Page as Page
import Pages.Meals.Status as Status
import Pages.Util.DateUtil as DateUtil
import Pages.Util.Links as Links
import Pages.Util.ViewUtil as ViewUtil
import Parser
import Url.Builder
import Util.Editing as Editing


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = .initialization
        , flagsWithJWT = .flagsWithJWT
        }
        model
    <|
        let
            viewEditMeals =
                List.map
                    (Either.unpack
                        (editOrDeleteMealLine model.flagsWithJWT.configuration)
                        (\e -> e.update |> editMealLine)
                    )

            ( button, creationLine ) =
                createMeal model.mealToAdd |> Either.unpack (\l -> ( [ l ], [] )) (\r -> ( [], [ r ] ))
        in
        div [ id "addMealView" ]
            (button
                ++ [ table []
                        [ colgroup []
                            [ col [] []
                            , col [] []
                            , col [] []
                            , col [ stringProperty "span" "3" ] []
                            ]
                        , thead []
                            [ tr [ class "tableHeader" ]
                                [ th [ scope "col" ] [ label [] [ text "Date" ] ]
                                , th [ scope "col" ] [ label [] [ text "Time" ] ]
                                , th [ scope "col" ] [ label [] [ text "Name" ] ]
                                , th [ colspan 3, scope "colgroup", class "controlsGroup" ] []
                                ]
                            ]
                        , tbody []
                            (creationLine
                                ++ viewEditMeals
                                    (model.meals
                                        |> Dict.values
                                        |> List.sortBy (Editing.field .date >> DateUtil.toString)
                                    )
                            )
                        ]
                   ]
            )


createMeal : Maybe MealCreationClientInput -> Either (Html Page.Msg) (Html Page.Msg)
createMeal maybeCreation =
    case maybeCreation of
        Nothing ->
            div [ id "addMeal" ]
                [ button
                    [ class "addButton"
                    , onClick (MealCreationClientInput.default |> Just |> Page.UpdateMealCreation)
                    ]
                    [ text "New meal" ]
                ]
                |> Left

        Just creation ->
            createMealLine creation |> Right


editOrDeleteMealLine : Configuration -> Meal -> Html Page.Msg
editOrDeleteMealLine configuration meal =
    tr [ class "editing" ]
        [ td [ class "editable" ] [ label [] [ text <| DateUtil.dateToString <| meal.date.date ] ]
        , td [ class "editable" ] [ label [] [ text <| Maybe.Extra.unwrap "" DateUtil.timeToString <| meal.date.time ] ]
        , td [ class "editable" ] [ label [] [ text <| Maybe.withDefault "" <| meal.name ] ]
        , td [ class "controls" ] [ button [ class "editButton", onClick (Page.EnterEditMeal meal.id) ] [ text "Edit" ] ]
        , td [ class "controls" ] [ button [ class "deleteButton", onClick (Page.DeleteMeal meal.id) ] [ text "Delete" ] ]
        , td [ class "controls" ]
            [ Links.linkButton
                { url =
                    Url.Builder.relative
                        [ configuration.mainPageURL
                        , "#"
                        , "meal-entry-editor"
                        , meal.id
                        ]
                        []
                , attributes = [ class "editorButton" ]
                , children = [ text "Entries" ]
                , isDisabled = False
                }
            ]
        ]


editMealLine : MealUpdate -> Html Page.Msg
editMealLine mealUpdate =
    editMealLineWith
        { saveMsg = Page.SaveMealEdit mealUpdate.id
        , dateLens = MealUpdateLens.date
        , nameLens = MealUpdateLens.name
        , updateMsg = Page.UpdateMeal
        , confirmOnClick = Page.SaveMealEdit mealUpdate.id
        , confirmName = "Save"
        , cancelOnClick = Page.ExitEditMealAt mealUpdate.id
        , cancelName = "Cancel"
        }
        mealUpdate


createMealLine : MealCreationClientInput -> Html Page.Msg
createMealLine mealCreation =
    editMealLineWith
        { saveMsg = Page.CreateMeal
        , dateLens = MealCreationClientInput.lenses.date
        , nameLens = MealCreationClientInput.lenses.name
        , updateMsg = Just >> Page.UpdateMealCreation
        , confirmOnClick = Page.CreateMeal
        , confirmName = "Add"
        , cancelOnClick = Page.UpdateMealCreation Nothing
        , cancelName = "Cancel"
        }
        mealCreation


editMealLineWith :
    { saveMsg : Page.Msg
    , dateLens : Lens editedValue SimpleDate
    , nameLens : Lens editedValue (Maybe String)
    , updateMsg : editedValue -> Page.Msg
    , confirmOnClick : Page.Msg
    , confirmName : String
    , cancelOnClick : Page.Msg
    , cancelName : String
    }
    -> editedValue
    -> Html Page.Msg
editMealLineWith handling editedValue =
    let
        date =
            handling.dateLens.get <| editedValue

        name =
            Maybe.withDefault "" <| handling.nameLens.get <| editedValue
    in
    tr [ class "editLine" ]
        [ td [ class "editable", class "date" ]
            [ input
                [ type_ "date"
                , value <| DateUtil.dateToString <| date.date
                , onInput
                    (Parser.run DateUtil.dateParser
                        >> Result.withDefault date.date
                        >> flip
                            (handling.dateLens
                                |> Compose.lensWithLens SimpleDateLens.date
                            ).set
                            editedValue
                        >> handling.updateMsg
                    )
                , onEnter handling.saveMsg
                ]
                []
            ]
        , td [ class "editable", class "time" ]
            [ input
                [ type_ "time"
                , value <| Maybe.Extra.unwrap "" DateUtil.timeToString <| date.time
                , onInput
                    (Parser.run DateUtil.timeParser
                        >> Result.toMaybe
                        >> flip
                            (handling.dateLens
                                |> Compose.lensWithLens SimpleDateLens.time
                            ).set
                            editedValue
                        >> handling.updateMsg
                    )
                , onEnter handling.saveMsg
                ]
                []
            ]
        , td [ class "editable" ]
            [ input
                [ value <| name
                , onInput
                    (Just
                        >> Maybe.Extra.filter (String.isEmpty >> not)
                        >> flip handling.nameLens.set editedValue
                        >> handling.updateMsg
                    )
                , onEnter handling.saveMsg
                ]
                []
            ]
        , td [ class "controls" ]
            [ button [ class "confirmButton", onClick handling.confirmOnClick ]
                [ text handling.confirmName ]
            ]
        , td [ class "controls" ]
            [ button [ class "cancelButton", onClick handling.cancelOnClick ]
                [ text handling.cancelName ]
            ]
        ]
