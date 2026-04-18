module Pages.Profiles.View exposing (..)

import Api.Auxiliary exposing (ProfileId)
import Api.Types.Profile exposing (Profile)
import Basics.Extra exposing (flip)
import Html exposing (Attribute, Html, button, input, td, text, th, tr)
import Html.Attributes exposing (value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.Profiles.Page as Page
import Pages.Profiles.ProfileCreationClientInput as ProfileCreationClientInput exposing (ProfileCreationClientInput)
import Pages.Profiles.ProfileUpdateClientInput as ProfileUpdateClientInput exposing (ProfileUpdateClientInput)
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.ParentEditor.Page
import Pages.Util.ParentEditor.View
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate
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
        { currentPage = Just ViewUtil.Profiles
        , matchesSearchText = \string profile -> SearchUtil.search string profile.name
        , sort = List.sortBy (.original >> .name)
        , tableHeader = tableHeader
        , viewLine = viewProfileLine
        , updateLine = .id >> updateProfileLine
        , deleteLine = deleteProfileLine
        , create =
            { ifCreating = createProfileLine
            , default = ProfileCreationClientInput.default
            , label = "New profile"
            , update = Pages.Util.ParentEditor.Page.UpdateCreation
            }
        , setSearchString = Pages.Util.ParentEditor.Page.SetSearchString
        , setPagination = Pages.Util.ParentEditor.Page.SetPagination
        , styling = Style.ids.addProfileView
        }


tableHeader : Html msg
tableHeader =
    Pages.Util.ParentEditor.View.tableHeaderWith
        { columns = [ th [] [ text "Name" ] ]
        , style = Style.classes.profileEditTable
        }


viewProfileLine : Profile -> Bool -> List (Html Page.LogicMsg)
viewProfileLine profile showControls =
    profileLineWith
        { controls =
            [ td [ Style.classes.controls ]
                [ button [ Style.classes.button.edit, Pages.Util.ParentEditor.Page.EnterEdit profile.id |> onClick ] [ text "Edit" ] ]
            , td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.delete, onClick <| Pages.Util.ParentEditor.Page.RequestDelete <| profile.id ]
                    [ text "Delete" ]
                ]
            ]
        , toggleMsg = Pages.Util.ParentEditor.Page.ToggleControls profile.id
        , showControls = showControls
        }
        profile


deleteProfileLine : Profile -> List (Html Page.LogicMsg)
deleteProfileLine profile =
    profileLineWith
        { controls =
            [ td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.delete, onClick <| Pages.Util.ParentEditor.Page.ConfirmDelete <| profile.id ]
                    [ text "Delete?" ]
                ]
            , td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.confirm, onClick <| Pages.Util.ParentEditor.Page.CancelDelete <| profile.id ]
                    [ text "Cancel" ]
                ]
            ]
        , toggleMsg = Pages.Util.ParentEditor.Page.ToggleControls profile.id
        , showControls = True
        }
        profile


profileInfoColumns : Profile -> List (HtmlUtil.Column msg)
profileInfoColumns profile =
    [ { attributes = [ Style.classes.editable ]
      , children = [ text profile.name ]
      }
    ]


profileLineWith :
    { controls : List (Html msg)
    , toggleMsg : msg
    , showControls : Bool
    }
    -> Profile
    -> List (Html msg)
profileLineWith ps =
    Pages.Util.ParentEditor.View.lineWith
        { rowWithControls =
            \profile ->
                { display = profileInfoColumns profile
                , controls = ps.controls
                }
        , toggleMsg = ps.toggleMsg
        , showControls = ps.showControls
        }


updateProfileLine : ProfileId -> ProfileUpdateClientInput -> List (Html Page.LogicMsg)
updateProfileLine profileId =
    editProfileLineWith
        { saveMsg = Pages.Util.ParentEditor.Page.SaveEdit profileId
        , nameLens = ProfileUpdateClientInput.lenses.name
        , updateMsg = Pages.Util.ParentEditor.Page.Edit profileId
        , confirmName = "Save"
        , cancelMsg = Pages.Util.ParentEditor.Page.ExitEdit profileId
        , cancelName = "Cancel"
        , rowStyles = [ Style.classes.editLine ]
        , toggleCommand = Pages.Util.ParentEditor.Page.ToggleControls profileId |> Just
        }


createProfileLine : ProfileCreationClientInput -> List (Html Page.LogicMsg)
createProfileLine profileCreationClientInput =
    editProfileLineWith
        { saveMsg = Pages.Util.ParentEditor.Page.Create
        , nameLens = ProfileCreationClientInput.lenses.name
        , updateMsg = Just >> Pages.Util.ParentEditor.Page.UpdateCreation
        , confirmName = "Add"
        , cancelMsg = Pages.Util.ParentEditor.Page.UpdateCreation Nothing
        , cancelName = "Cancel"
        , rowStyles = [ Style.classes.editLine ]
        , toggleCommand = Nothing
        }
        profileCreationClientInput


editProfileLineWith :
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
editProfileLineWith handling editedValue =
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
