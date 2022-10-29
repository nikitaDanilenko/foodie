module Pages.ReferenceMaps.View exposing (view)

import Addresses.Frontend
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Dict
import Either exposing (Either(..))
import Html exposing (Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, disabled, scope, value)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.ReferenceMaps.Page as Page
import Pages.ReferenceMaps.Pagination as Pagination
import Pages.ReferenceMaps.ReferenceMapCreationClientInput as ReferenceMapCreationClientInput exposing (ReferenceMapCreationClientInput)
import Pages.ReferenceMaps.ReferenceMapUpdateClientInput as ReferenceMapUpdateClientInput exposing (ReferenceMapUpdateClientInput)
import Pages.ReferenceMaps.Status as Status
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)
import Pages.Util.ViewUtil as ViewUtil
import Paginate
import Util.Editing as Editing
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = Page.lenses.initialization.get
        , configuration = .authorizedAccess >> .configuration
        , jwt = .authorizedAccess >> .jwt >> Just
        , currentPage = Just ViewUtil.ReferenceMaps
        , showNavigation = True
        }
        model
    <|
        let
            viewEditReferenceMap =
                Either.unpack
                    (editOrDeleteReferenceMapLine model.authorizedAccess.configuration)
                    (\e -> e.update |> editReferenceMapLine)

            viewEditReferenceMaps =
                model.referenceMaps
                    |> Dict.filter (\_ v -> SearchUtil.search model.searchString (Editing.field .name v))
                    |> Dict.values
                    |> List.sortBy (Editing.field .name >> String.toLower)
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.pagination |> Compose.lensWithLens Pagination.lenses.referenceMaps
                        }
                        model

            ( button, creationLine ) =
                createReferenceMap model.referenceMapToAdd |> Either.unpack (\l -> ( [ l ], [] )) (\r -> ( [], [ r ] ))
        in
        div [ Style.ids.addReferenceMapView ]
            (button
                ++ [ HtmlUtil.searchAreaWith
                        { msg = Page.SetSearchString
                        , searchString = model.searchString
                        }
                   , table []
                        [ colgroup []
                            [ col [] []
                            , col [ stringProperty "span" "3" ] []
                            ]
                        , thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                                , th [ colspan 3, scope "colgroup", Style.classes.controlsGroup ] []
                                ]
                            ]
                        , tbody []
                            (creationLine
                                ++ (viewEditReferenceMaps |> Paginate.page |> List.map viewEditReferenceMap)
                            )
                        ]
                   , div [ Style.classes.pagination ]
                        [ ViewUtil.pagerButtons
                            { msg =
                                PaginationSettings.updateCurrentPage
                                    { pagination = Page.lenses.pagination
                                    , items = Pagination.lenses.referenceMaps
                                    }
                                    model
                                    >> Page.SetPagination
                            , elements = viewEditReferenceMaps
                            }
                        ]
                   ]
            )


createReferenceMap : Maybe ReferenceMapCreationClientInput -> Either (Html Page.Msg) (Html Page.Msg)
createReferenceMap maybeCreation =
    case maybeCreation of
        Nothing ->
            div [ Style.ids.add ]
                [ button
                    [ Style.classes.button.add
                    , onClick <| Page.UpdateReferenceMapCreation <| Just <| ReferenceMapCreationClientInput.default
                    ]
                    [ text "New reference map" ]
                ]
                |> Left

        Just creation ->
            createReferenceMapLine creation |> Right


editOrDeleteReferenceMapLine : Configuration -> ReferenceMap -> Html Page.Msg
editOrDeleteReferenceMapLine configuration referenceMap =
    let
        editMsg =
            Page.EnterEditReferenceMap referenceMap.id
    in
    tr [ Style.classes.editing ]
        [ td [ Style.classes.editable, onClick editMsg ] [ label [] [ text referenceMap.name ] ]
        , td [ Style.classes.controls ]
            [ button [ Style.classes.button.edit, onClick editMsg ] [ text "Edit" ] ]
        , td [ Style.classes.controls ]
            [ button
                [ Style.classes.button.delete, onClick (Page.DeleteReferenceMap referenceMap.id) ]
                [ text "Delete" ]
            ]
        , td [ Style.classes.controls ]
            [ Links.linkButton
                { url = Links.frontendPage configuration <| Addresses.Frontend.referenceEntries.address <| referenceMap.id
                , attributes = [ Style.classes.button.editor ]
                , children = [ text "Entries" ]
                }
            ]
        ]


editReferenceMapLine : ReferenceMapUpdateClientInput -> Html Page.Msg
editReferenceMapLine referenceMapUpdateClientInput =
    editReferenceMapLineWith
        { saveMsg = Page.SaveReferenceMapEdit referenceMapUpdateClientInput.id
        , nameLens = ReferenceMapUpdateClientInput.lenses.name
        , updateMsg = Page.UpdateReferenceMap
        , confirmName = "Save"
        , cancelMsg = Page.ExitEditReferenceMapAt referenceMapUpdateClientInput.id
        , cancelName = "Cancel"
        }
        referenceMapUpdateClientInput


createReferenceMapLine : ReferenceMapCreationClientInput -> Html Page.Msg
createReferenceMapLine referenceMapCreationClientInput =
    editReferenceMapLineWith
        { saveMsg = Page.CreateReferenceMap
        , nameLens = ReferenceMapCreationClientInput.lenses.name
        , updateMsg = Just >> Page.UpdateReferenceMapCreation
        , confirmName = "Add"
        , cancelMsg = Page.UpdateReferenceMapCreation Nothing
        , cancelName = "Cancel"
        }
        referenceMapCreationClientInput


editReferenceMapLineWith :
    { saveMsg : Page.Msg
    , nameLens : Lens editedValue (ValidatedInput String)
    , updateMsg : editedValue -> Page.Msg
    , confirmName : String
    , cancelMsg : Page.Msg
    , cancelName : String
    }
    -> editedValue
    -> Html Page.Msg
editReferenceMapLineWith handling editedValue =
    let
        validInput =
            handling.nameLens.get editedValue
                |> ValidatedInput.isValid

        validatedSaveAction =
            if validInput then
                [ onEnter handling.saveMsg ]

            else
                []
    in
    tr [ Style.classes.editLine ]
        [ td [ Style.classes.editable ]
            [ input
                ([ value <| .text <| handling.nameLens.get <| editedValue
                 , onInput
                    (flip (ValidatedInput.lift handling.nameLens).set editedValue
                        >> handling.updateMsg
                    )
                 , HtmlUtil.onEscape handling.cancelMsg
                 ]
                    ++ validatedSaveAction
                )
                []
            ]
        , td [ Style.classes.controls ]
            [ button
                [ Style.classes.button.confirm
                , onClick handling.saveMsg
                , disabled <| not <| validInput
                ]
                [ text handling.confirmName ]
            ]
        , td [ Style.classes.controls ]
            [ button [ Style.classes.button.cancel, onClick handling.cancelMsg ]
                [ text handling.cancelName ]
            ]
        , td [] []
        ]
