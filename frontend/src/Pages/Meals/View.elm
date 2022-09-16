module Pages.Meals.View exposing (view)

import Api.Lenses.MealUpdateLens as MealUpdateLens
import Api.Lenses.SimpleDateLens as SimpleDateLens
import Api.Types.Meal exposing (Meal)
import Api.Types.MealUpdate exposing (MealUpdate)
import Api.Types.SimpleDate exposing (SimpleDate)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Dict
import Either
import Html exposing (Html, button, div, input, label, td, text, thead, tr)
import Html.Attributes exposing (class, id, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Meals.MealCreationClientInput as MealCreationClientInput exposing (MealCreationClientInput)
import Pages.Meals.Page as Page
import Pages.Util.DateUtil as DateUtil
import Pages.Util.Links as Links
import Parser
import Url.Builder
import Util.Editing as Editing


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
        (createMeal model.mealToAdd
            :: thead []
                [ tr []
                    [ td [] [ label [] [ text "Name" ] ]
                    , td [] [ label [] [ text "Description" ] ]
                    ]
                ]
            :: viewEditMeals
                (model.meals
                    |> Dict.values
                    |> List.sortBy (Editing.field .date >> DateUtil.toString)
                )
        )


createMeal : Maybe MealCreationClientInput -> Html Page.Msg
createMeal maybeCreation =
    case maybeCreation of
        Nothing ->
            div [ id "addMeal" ]
                [ button
                    [ class "button"
                    , onClick (MealCreationClientInput.default |> Just |> Page.UpdateMealCreation)
                    ]
                    [ text "New meal" ]
                ]

        Just creation ->
            createMealLine creation


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
    tr [ id "mealLine" ]
        [ td []
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
            , input
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
        , td []
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
        , td []
            [ button [ class "button", onClick handling.confirmOnClick ]
                [ text handling.confirmName ]
            ]
        , td []
            [ button [ class "button", onClick handling.cancelOnClick ]
                [ text handling.cancelName ]
            ]
        ]
