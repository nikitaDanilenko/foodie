module Pages.Meals.Editor.View exposing (editMealLineWith, mealLineWith, tableHeader, view)

import Addresses.Frontend
import Api.Auxiliary exposing (MealEntryId, MealId, ProfileId)
import Api.Types.Meal exposing (Meal)
import Api.Types.Profile exposing (Profile)
import Api.Types.SimpleDate exposing (SimpleDate)
import Basics.Extra exposing (flip)
import Html exposing (Attribute, Html, button, input, td, text, th, tr)
import Html.Attributes exposing (type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)
import Pages.Meals.Editor.MealCreationClientInput as MealCreationClientInput exposing (MealCreationClientInput)
import Pages.Meals.Editor.MealUpdateClientInput as MealUpdateClientInput exposing (MealUpdateClientInput)
import Pages.Meals.Editor.Page as Page
import Pages.Util.DateUtil as DateUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Links as Links
import Pages.Util.ParentEditor.Page
import Pages.Util.ParentEditor.View
import Pages.Util.SimpleDateInput as SimpleDateInput exposing (SimpleDateInput)
import Pages.Util.Style as Style
import Pages.View.Tristate as Tristate
import Parser
import Util.MaybeUtil as MaybeUtil
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view model =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }
        model


viewMain : Page.Main -> Html Page.LogicMsg
viewMain main =
    Pages.Util.ParentEditor.View.viewParentsWith
        { currentPage = Nothing
        , matchesSearchText =
            \string meal ->
                SearchUtil.search string (meal.name |> Maybe.withDefault "")
                    || SearchUtil.search string (meal.date |> DateUtil.toString)
        , sort = List.sortBy (.original >> .date >> DateUtil.toString) >> List.reverse
        , tableHeader = tableHeader
        , viewLine = viewMealLine main.profile
        , updateLine = .id >> updateMealLine main.profile.name
        , deleteLine = deleteMealLine main.profile.name
        , create =
            { ifCreating = createMealLine main.profile.name
            , default = MealCreationClientInput.default
            , label = "New meal for " ++ main.profile.name
            , update = Pages.Util.ParentEditor.Page.UpdateCreation >> Page.ParentEditorMsg
            }
        , setSearchString = Pages.Util.ParentEditor.Page.SetSearchString >> Page.ParentEditorMsg
        , setPagination = Pages.Util.ParentEditor.Page.SetPagination >> Page.ParentEditorMsg
        , styling = Style.ids.addMealView
        }
        main.parentEditor


tableHeader : Html msg
tableHeader =
    Pages.Util.ParentEditor.View.tableHeaderWith
        { columns =
            [ th [] [ text "Date" ]
            , th [] [ text "Time" ]
            , th [] [ text "Profile" ]
            , th [] [ text "Name" ]
            ]
        , style = Style.classes.mealEditTable
        }


viewMealLine : Profile -> Meal -> Bool -> List (Html Page.LogicMsg)
viewMealLine profile meal showControls =
    let
        mealKey =
            ( profile.id, meal.id )
    in
    mealLineWith
        { controls =
            [ td [ Style.classes.controls ] [ button [ Style.classes.button.edit, onClick <| Pages.Util.ParentEditor.Page.EnterEdit <| meal.id ] [ text "Edit" ] ]
            , td [ Style.classes.controls ]
                [ Links.linkButton
                    { url = Links.frontendPage <| Addresses.Frontend.mealEntryEditor.address <| mealKey
                    , attributes = [ Style.classes.button.editor ]
                    , children = [ text "Entries" ]
                    }
                ]
            , td [ Style.classes.controls ]
                [ button [ Style.classes.button.delete, onClick <| Pages.Util.ParentEditor.Page.RequestDelete <| meal.id ] [ text "Delete" ] ]
            , td [ Style.classes.controls ]
                [ Links.linkButton
                    { url = Links.frontendPage <| Addresses.Frontend.statisticsMealSelect.address <| mealKey
                    , attributes = [ Style.classes.button.nutrients ]
                    , children = [ text "Nutrients" ]
                    }
                ]
            , td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.confirm
                    , onClick <| Pages.Util.ParentEditor.Page.Duplicate <| meal.id
                    ]
                    [ text "Duplicate" ]
                ]
            ]
                |> List.map (Html.map Page.ParentEditorMsg)
        , toggleMsg = Pages.Util.ParentEditor.Page.ToggleControls meal.id |> Page.ParentEditorMsg
        , showControls = showControls
        }
        profile.name
        meal


deleteMealLine : String -> Meal -> List (Html Page.LogicMsg)
deleteMealLine profileName meal =
    mealLineWith
        { controls =
            [ td [ Style.classes.controls ]
                [ button [ Style.classes.button.delete, onClick <| Pages.Util.ParentEditor.Page.ConfirmDelete meal.id ] [ text "Delete?" ] ]
            , td [ Style.classes.controls ]
                [ button [ Style.classes.button.confirm, onClick <| Pages.Util.ParentEditor.Page.CancelDelete meal.id ] [ text "Cancel" ] ]
            ]
                |> List.map (Html.map Page.ParentEditorMsg)
        , toggleMsg = Pages.Util.ParentEditor.Page.ToggleControls meal.id |> Page.ParentEditorMsg
        , showControls = True
        }
        profileName
        meal


mealInfoColumns : String -> Meal -> List (HtmlUtil.Column msg)
mealInfoColumns profileName meal =
    [ { attributes = [ Style.classes.editable ]
      , children = [ text <| DateUtil.dateToPrettyString <| meal.date.date ]
      }
    , { attributes = [ Style.classes.editable ]
      , children = [ text <| Maybe.Extra.unwrap "" DateUtil.timeToString <| meal.date.time ]
      }
    , { attributes = [ Style.classes.editable ]
      , children = [ text <| profileName ]
      }
    , { attributes = [ Style.classes.editable ]
      , children = [ text <| Maybe.withDefault "" <| meal.name ]
      }
    ]


mealLineWith :
    { controls : List (Html msg)
    , toggleMsg : msg
    , showControls : Bool
    }
    -> String
    -> Meal
    -> List (Html msg)
mealLineWith ps profileName =
    Pages.Util.ParentEditor.View.lineWith
        { rowWithControls =
            \meal ->
                { display = mealInfoColumns profileName meal
                , controls = ps.controls
                }
        , toggleMsg = ps.toggleMsg
        , showControls = ps.showControls
        }


updateMealLine : String -> MealId -> MealUpdateClientInput -> List (Html Page.LogicMsg)
updateMealLine profileName mealId =
    editMealLineWith
        { saveMsg = Pages.Util.ParentEditor.Page.SaveEdit mealId
        , dateLens = MealUpdateClientInput.lenses.date
        , nameLens = MealUpdateClientInput.lenses.name
        , updateMsg = Pages.Util.ParentEditor.Page.Edit mealId
        , confirmName = "Save"
        , cancelMsg = Pages.Util.ParentEditor.Page.ExitEdit mealId
        , cancelName = "Cancel"
        , rowStyles = [ Style.classes.editLine ]
        , toggleCommand = Pages.Util.ParentEditor.Page.ToggleControls mealId |> Just
        }
        profileName
        >> List.map (Html.map Page.ParentEditorMsg)


createMealLine : String -> MealCreationClientInput -> List (Html Page.LogicMsg)
createMealLine profileName =
    editMealLineWith
        { saveMsg = Pages.Util.ParentEditor.Page.Create
        , dateLens = MealCreationClientInput.lenses.date
        , nameLens = MealCreationClientInput.lenses.name
        , updateMsg = Just >> Pages.Util.ParentEditor.Page.UpdateCreation
        , confirmName = "Add"
        , cancelMsg = Pages.Util.ParentEditor.Page.UpdateCreation Nothing
        , cancelName = "Cancel"
        , rowStyles = [ Style.classes.editLine ]
        , toggleCommand = Nothing
        }
        profileName
        >> List.map (Html.map Page.ParentEditorMsg)


editMealLineWith :
    { saveMsg : msg
    , dateLens : Lens editedValue SimpleDateInput
    , nameLens : Optional editedValue String
    , updateMsg : editedValue -> msg
    , confirmName : String
    , cancelMsg : msg
    , cancelName : String
    , rowStyles : List (Attribute msg)
    , toggleCommand : Maybe msg
    }
    -> String
    -> editedValue
    -> List (Html msg)
editMealLineWith handling profileName editedValue =
    let
        date =
            handling.dateLens.get <| editedValue

        deepDateLens =
            handling.dateLens
                |> Compose.lensWithLens SimpleDateInput.lenses.date

        deepTimeLens =
            handling.dateLens
                |> Compose.lensWithLens SimpleDateInput.lenses.time

        dateValue =
            date
                |> .date
                |> Maybe.map (DateUtil.dateToString >> value)
                |> Maybe.Extra.toList

        dateParsedInteraction =
            Parser.run DateUtil.dateParser
                >> Result.toMaybe
                >> flip
                    deepDateLens.set
                    editedValue
                >> handling.updateMsg

        validatedSaveAction =
            MaybeUtil.optional (deepDateLens.get editedValue |> Maybe.Extra.isJust) <| onEnter handling.saveMsg

        timeValue =
            date
                |> .time
                |> Maybe.map (DateUtil.timeToString >> value)
                |> Maybe.Extra.toList

        timeInteraction =
            Parser.run DateUtil.timeParser
                >> Result.toMaybe
                >> flip
                    deepTimeLens.set
                    editedValue
                >> handling.updateMsg

        name =
            Maybe.withDefault "" <| handling.nameLens.getOption <| editedValue

        validInput =
            Maybe.Extra.isJust <| date.date

        infoColumns =
            [ td [ Style.classes.editable, Style.classes.date ]
                [ input
                    ([ type_ <| "date"
                     , Style.classes.date
                     , onInput <| dateParsedInteraction
                     , HtmlUtil.onEscape handling.cancelMsg
                     ]
                        ++ dateValue
                    )
                    []
                ]
            , td [ Style.classes.editable, Style.classes.time ]
                [ input
                    ([ type_ "time"
                     , Style.classes.time
                     , onInput timeInteraction
                     , HtmlUtil.onEscape handling.cancelMsg
                     ]
                        ++ timeValue
                    )
                    []
                ]
            , td [ Style.classes.editable ]
                [ text profileName ]
            , td [ Style.classes.editable ]
                [ input
                    ([ MaybeUtil.defined <| value <| name
                     , MaybeUtil.defined <|
                        onInput <|
                            flip handling.nameLens.set editedValue
                                >> handling.updateMsg
                     , MaybeUtil.defined <| HtmlUtil.onEscape handling.cancelMsg
                     , validatedSaveAction
                     ]
                        |> Maybe.Extra.values
                    )
                    []
                ]
            ]

        controlsRow =
            Pages.Util.ParentEditor.View.controlsRowWith
                { colspan = infoColumns |> List.length
                , validInput = validInput
                , confirm =
                    { msg = handling.saveMsg
                    , name = handling.confirmName
                    }
                , cancel =
                    { msg = handling.cancelMsg
                    , name = handling.cancelName
                    }
                }

        commandToggle =
            handling.toggleCommand
                |> Maybe.Extra.unwrap []
                    (HtmlUtil.toggleControlsCell >> List.singleton)
    in
    [ tr handling.rowStyles (infoColumns ++ commandToggle)
    , controlsRow
    ]
