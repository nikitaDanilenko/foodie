module Pages.Util.Parent.Handler exposing (..)

import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.DateUtil as DateUtil
import Pages.Util.Links as Links
import Pages.Util.Parent.Page as Page
import Pages.View.Tristate as Tristate
import Result.Extra
import Task
import Util.Editing as Editing


updateLogic :
    { toUpdate : parent -> update
    , idOf : parent -> parentId
    , save : AuthorizedAccess -> parentId -> update -> Maybe (Cmd (Page.LogicMsg parent update))
    , delete : AuthorizedAccess -> parentId -> Cmd (Page.LogicMsg parent update)
    , duplicate : AuthorizedAccess -> parentId -> DateUtil.Timestamp -> Cmd (Page.LogicMsg parent update)
    , navigateAfterDeletionAddress : () -> List String
    , navigateAfterDuplicationAddress : parentId -> List String
    }
    -> Page.LogicMsg parent update
    -> Page.Model parent update
    -> ( Page.Model parent update, Cmd (Page.LogicMsg parent update) )
updateLogic ps msg model =
    let
        gotFetchResponse result =
            ( result
                |> Result.Extra.unpack (Tristate.toError model)
                    (\parent ->
                        model
                            |> Tristate.mapInitial (Page.lenses.initial.parent.set (parent |> Just))
                    )
            , Cmd.none
            )

        toggleControls =
            ( model
                |> Tristate.mapMain (Lens.modify Page.lenses.main.parent Editing.toggleControls)
            , Cmd.none
            )

        edit update =
            ( model
                |> Tristate.mapMain
                    ((Page.lenses.main.parent
                        |> Compose.lensWithOptional Editing.lenses.update
                     ).set
                        update
                    )
            , Cmd.none
            )

        saveEdit parent =
            ( model
            , model
                |> Tristate.lenses.main.getOption
                |> Maybe.andThen
                    (\main ->
                        main
                            |> Page.lenses.main.parent.get
                            |> Editing.extractUpdate
                            |> Maybe.andThen
                                (ps.save
                                    { configuration = model.configuration
                                    , jwt = main.jwt
                                    }
                                    (parent |> ps.idOf)
                                )
                    )
                |> Maybe.withDefault Cmd.none
            )

        gotSaveEditResponse result =
            ( result
                |> Result.Extra.unpack (Tristate.toError model)
                    (\parent ->
                        model
                            |> Tristate.mapMain (Page.lenses.main.parent.set (parent |> Editing.asView))
                    )
            , Cmd.none
            )

        enterEdit =
            ( model
                |> Tristate.mapMain (Lens.modify Page.lenses.main.parent (Editing.toUpdate ps.toUpdate))
            , Cmd.none
            )

        exitEdit =
            ( model
                |> Tristate.mapMain (Lens.modify Page.lenses.main.parent Editing.toView)
            , Cmd.none
            )

        requestDelete =
            ( model
                |> Tristate.mapMain (Lens.modify Page.lenses.main.parent Editing.toDelete)
            , Cmd.none
            )

        confirmDelete =
            ( model
            , model
                |> Tristate.foldMain Cmd.none
                    (\main ->
                        ps.delete
                            { configuration = model.configuration
                            , jwt = main.jwt
                            }
                            (main.parent.original |> ps.idOf)
                    )
            )

        cancelDelete =
            ( model
                |> Tristate.mapMain (Lens.modify Page.lenses.main.parent Editing.toView)
            , Cmd.none
            )

        gotDeleteResponse result =
            result
                |> Result.Extra.unpack (\error -> ( Tristate.toError model error, Cmd.none ))
                    (\_ ->
                        ( model
                        , Links.loadFrontendPage
                            (() |> ps.navigateAfterDeletionAddress)
                        )
                    )

        duplicate =
            ( model
            , DateUtil.now
                |> Task.perform Page.GotDuplicationTimestamp
            )

        gotDuplicationTimestamp timestamp =
            ( model
            , model
                |> Tristate.foldMain Cmd.none
                    (\main ->
                        ps.duplicate
                            { configuration = model.configuration
                            , jwt = main.jwt
                            }
                            (main.parent.original |> ps.idOf)
                            timestamp
                    )
            )

        gotDuplicateResponse result =
            result
                |> Result.Extra.unpack (\error -> ( Tristate.toError model error, Cmd.none ))
                    (\parent ->
                        ( model
                        , Links.loadFrontendPage
                            (parent |> ps.idOf |> ps.navigateAfterDuplicationAddress)
                        )
                    )
    in
    case msg of
        Page.GotFetchResponse result ->
            gotFetchResponse result

        Page.Edit update ->
            edit update

        Page.SaveEdit parent ->
            saveEdit parent

        Page.GotSaveEditResponse result ->
            gotSaveEditResponse result

        Page.EnterEdit ->
            enterEdit

        Page.ExitEdit ->
            exitEdit

        Page.RequestDelete ->
            requestDelete

        Page.ConfirmDelete ->
            confirmDelete

        Page.CancelDelete ->
            cancelDelete

        Page.GotDeleteResponse result ->
            gotDeleteResponse result

        Page.Duplicate ->
            duplicate

        Page.GotDuplicationTimestamp timestamp ->
            gotDuplicationTimestamp timestamp

        Page.GotDuplicateResponse result ->
            gotDuplicateResponse result

        Page.ToggleControls ->
            toggleControls
