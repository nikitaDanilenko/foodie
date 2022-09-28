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
import Html.Attributes exposing (colspan, scope, type_, value)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Meals.MealCreationClientInput as MealCreationClientInput exposing (MealCreationClientInput)
import Pages.Meals.Page as Page
import Pages.Meals.Pagination as Pagination
import Pages.Meals.Status as Status
import Pages.Util.DateUtil as DateUtil
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Paginate
import Parser
import Url.Builder
import Util.Editing as Editing


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = .initialization
        , flagsWithJWT = .flagsWithJWT
        , currentPage = Just ViewUtil.Meals
        }
        model
    <|
        let
            viewEditMeal =
                Either.unpack
                    (editOrDeleteMealLine model.flagsWithJWT.configuration)
                    (\e -> e.update |> editMealLine)

            viewEditMeals =
                model.meals
                    |> Dict.values
                    |> List.sortBy (Editing.field .date >> DateUtil.toString)
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.pagination |> Compose.lensWithLens Pagination.lenses.meals }
                        model

            ( button, creationLine ) =
                createMeal model.mealToAdd |> Either.unpack (\l -> ( [ l ], [] )) (\r -> ( [], [ r ] ))
        in
        div [ Style.ids.addMealView ]
            (button
                ++ [ table []
                        [ colgroup []
                            [ col [] []
                            , col [] []
                            , col [] []
                            , col [ stringProperty "span" "3" ] []
                            ]
                        , thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [ scope "col" ] [ label [] [ text "Date" ] ]
                                , th [ scope "col" ] [ label [] [ text "Time" ] ]
                                , th [ scope "col" ] [ label [] [ text "Name" ] ]
                                , th [ colspan 3, scope "colgroup", Style.classes.controlsGroup ] []
                                ]
                            ]
                        , tbody []
                            (creationLine
                                ++ (viewEditMeals
                                        |> Paginate.page
                                        |> List.map viewEditMeal
                                   )
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
                            , elements = viewEditMeals
                            }
                        ]
                   ]
            )


createMeal : Maybe MealCreationClientInput -> Either (Html Page.Msg) (Html Page.Msg)
createMeal maybeCreation =
    case maybeCreation of
        Nothing ->
            div [ Style.ids.add ]
                [ button
                    [ Style.classes.button.add
                    , onClick (MealCreationClientInput.default |> Just |> Page.UpdateMealCreation)
                    ]
                    [ text "New meal" ]
                ]
                |> Left

        Just creation ->
            createMealLine creation |> Right


editOrDeleteMealLine : Configuration -> Meal -> Html Page.Msg
editOrDeleteMealLine configuration meal =
    tr [ Style.classes.editing ]
        [ td [ Style.classes.editable ] [ label [] [ text <| DateUtil.dateToString <| meal.date.date ] ]
        , td [ Style.classes.editable ] [ label [] [ text <| Maybe.Extra.unwrap "" DateUtil.timeToString <| meal.date.time ] ]
        , td [ Style.classes.editable ] [ label [] [ text <| Maybe.withDefault "" <| meal.name ] ]
        , td [ Style.classes.controls ] [ button [ Style.classes.button.edit, onClick (Page.EnterEditMeal meal.id) ] [ text "Edit" ] ]
        , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.DeleteMeal meal.id) ] [ text "Delete" ] ]
        , td [ Style.classes.controls ]
            [ Links.linkButton
                { url =
                    Url.Builder.relative
                        [ configuration.mainPageURL
                        , "#"
                        , "meal-entry-editor"
                        , meal.id
                        ]
                        []
                , attributes = [ Style.classes.button.editor ]
                , children = [ text "Entries" ]
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
    tr [ Style.classes.editLine ]
        [ td [ Style.classes.editable, Style.classes.date ]
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
                , Style.classes.date
                ]
                []
            ]
        , td [ Style.classes.editable, Style.classes.time ]
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
                , Style.classes.time
                ]
                []
            ]
        , td [ Style.classes.editable ]
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
        , td [ Style.classes.controls ]
            [ button [ Style.classes.button.confirm, onClick handling.confirmOnClick ]
                [ text handling.confirmName ]
            ]
        , td [ Style.classes.controls ]
            [ button [ Style.classes.button.cancel, onClick handling.cancelOnClick ]
                [ text handling.cancelName ]
            ]
        ]
