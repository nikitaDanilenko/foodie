module Pages.ReferenceMaps.View exposing (editReferenceMapLineWith, referenceMapLineWith, tableHeader, view)

import Addresses.Frontend
import Api.Auxiliary exposing (ReferenceMapId)
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Basics.Extra exposing (flip)
import Html exposing (Attribute, Html, button, input, label, td, text, th, tr)
import Html.Attributes exposing (value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.ReferenceMaps.Page as Page
import Pages.ReferenceMaps.ReferenceMapCreationClientInput as ReferenceMapCreationClientInput exposing (ReferenceMapCreationClientInput)
import Pages.ReferenceMaps.ReferenceMapUpdateClientInput as ReferenceMapUpdateClientInput exposing (ReferenceMapUpdateClientInput)
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Links as Links
import Pages.Util.ParentEditor.Page
import Pages.Util.ParentEditor.View
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate
import Util.Editing
import Util.MaybeUtil as MaybeUtil
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }


viewMain : Page.Main -> Html Page.LogicMsg
viewMain =
    Pages.Util.ParentEditor.View.viewParentsWith
        { currentPage = Just ViewUtil.ReferenceMaps
        , matchesSearchText = \string referenceMap -> SearchUtil.search string referenceMap.name
        , sort = List.sortBy (.original >> .name)
        , tableHeader = tableHeader
        , viewLine = viewReferenceMapLine
        , updateLine = .id >> updateReferenceMapLine
        , deleteLine = deleteReferenceMapLine
        , create =
            { ifCreating = createReferenceMapLine
            , default = ReferenceMapCreationClientInput.default
            , label = "New reference map"
            , update = Pages.Util.ParentEditor.Page.UpdateCreation
            }
        , setSearchString = Pages.Util.ParentEditor.Page.SetSearchString
        , setPagination = Pages.Util.ParentEditor.Page.SetPagination
        , styling = Style.ids.addReferenceMapView
        }


tableHeader : Html msg
tableHeader =
    Pages.Util.ParentEditor.View.tableHeaderWith
        { columns = [ th [] [ label [] [ text "Name" ] ] ]
        , style = Style.classes.referenceMapEditTable
        }


viewReferenceMapLine : ReferenceMap -> Bool -> List (Html Page.LogicMsg)
viewReferenceMapLine referenceMap showControls =
    referenceMapLineWith
        { controls =
            [ td [ Style.classes.controls ]
                [ button [ Style.classes.button.edit, Pages.Util.ParentEditor.Page.EnterEdit referenceMap.id |> onClick ] [ text "Edit" ] ]
            , td [ Style.classes.controls ]
                [ Links.linkButton
                    { url = Links.frontendPage <| Addresses.Frontend.referenceEntries.address <| referenceMap.id
                    , attributes = [ Style.classes.button.editor ]
                    , children = [ text "Entries" ]
                    }
                ]
            , td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.delete, onClick <| Pages.Util.ParentEditor.Page.RequestDelete <| referenceMap.id ]
                    [ text "Delete" ]
                ]
            , td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.confirm, onClick <| Pages.Util.ParentEditor.Page.Duplicate <| referenceMap.id ]
                    [ text "Duplicate" ]
                ]
            ]
        , toggleMsg = Pages.Util.ParentEditor.Page.ToggleControls referenceMap.id
        , showControls = showControls
        }
        referenceMap


deleteReferenceMapLine : ReferenceMap -> List (Html Page.LogicMsg)
deleteReferenceMapLine referenceMap =
    referenceMapLineWith
        { controls =
            [ td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.delete, onClick <| Pages.Util.ParentEditor.Page.ConfirmDelete <| referenceMap.id ]
                    [ text "Delete?" ]
                ]
            , td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.confirm, onClick <| Pages.Util.ParentEditor.Page.CancelDelete <| referenceMap.id ]
                    [ text "Cancel" ]
                ]
            ]
        , toggleMsg = Pages.Util.ParentEditor.Page.ToggleControls referenceMap.id
        , showControls = True
        }
        referenceMap


referenceMapInfoColumns : ReferenceMap -> List (HtmlUtil.Column msg)
referenceMapInfoColumns referenceMap =
    [ { attributes = [ Style.classes.editable ]
      , children = [ label [] [ text referenceMap.name ] ]
      }
    ]


referenceMapLineWith :
    { controls : List (Html msg)
    , toggleMsg : msg
    , showControls : Bool
    }
    -> ReferenceMap
    -> List (Html msg)
referenceMapLineWith ps =
    Pages.Util.ParentEditor.View.lineWith
        { rowWithControls =
            \referenceMap ->
                { display = referenceMapInfoColumns referenceMap
                , controls = ps.controls
                }
        , toggleMsg = ps.toggleMsg
        , showControls = ps.showControls
        }


updateReferenceMapLine : ReferenceMapId -> ReferenceMapUpdateClientInput -> List (Html Page.LogicMsg)
updateReferenceMapLine referenceMapId =
    editReferenceMapLineWith
        { saveMsg = Pages.Util.ParentEditor.Page.SaveEdit referenceMapId
        , nameLens = ReferenceMapUpdateClientInput.lenses.name
        , updateMsg = Pages.Util.ParentEditor.Page.Edit referenceMapId
        , confirmName = "Save"
        , cancelMsg = Pages.Util.ParentEditor.Page.ExitEdit referenceMapId
        , cancelName = "Cancel"
        , rowStyles = [ Style.classes.editLine ]
        , toggleCommand = Pages.Util.ParentEditor.Page.ToggleControls referenceMapId |> Just
        }


createReferenceMapLine : ReferenceMapCreationClientInput -> List (Html Page.LogicMsg)
createReferenceMapLine referenceMapCreationClientInput =
    editReferenceMapLineWith
        { saveMsg = Pages.Util.ParentEditor.Page.Create
        , nameLens = ReferenceMapCreationClientInput.lenses.name
        , updateMsg = Just >> Pages.Util.ParentEditor.Page.UpdateCreation
        , confirmName = "Add"
        , cancelMsg = Pages.Util.ParentEditor.Page.UpdateCreation Nothing
        , cancelName = "Cancel"
        , rowStyles = [ Style.classes.editLine ]
        , toggleCommand = Nothing
        }
        referenceMapCreationClientInput


editReferenceMapLineWith :
    { saveMsg : msg
    , nameLens : Lens editedValue (ValidatedInput String)
    , updateMsg : editedValue -> msg
    , confirmName : String
    , cancelMsg : msg
    , cancelName : String
    , rowStyles : List (Attribute msg)
    , toggleCommand : Maybe msg
    }
    -> editedValue
    -> List (Html msg)
editReferenceMapLineWith handling editedValue =
    let
        validInput =
            handling.nameLens.get editedValue
                |> ValidatedInput.isValid

        validatedSaveAction =
            MaybeUtil.optional validInput <| onEnter handling.saveMsg

        infoColumns =
            [ td [ Style.classes.editable ]
                [ input
                    ([ MaybeUtil.defined <| value <| .text <| handling.nameLens.get <| editedValue
                     , MaybeUtil.defined <|
                        onInput <|
                            flip (ValidatedInput.lift handling.nameLens).set editedValue
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
