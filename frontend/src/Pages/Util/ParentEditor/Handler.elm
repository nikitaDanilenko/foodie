module Pages.Util.ParentEditor.Handler exposing (updateLogic)

import Maybe.Extra
import Monocle.Compose as Compose
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.DateUtil as DateUtil
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.ParentEditor.Page as Page
import Pages.Util.ParentEditor.Pagination as Pagination
import Pages.View.Tristate as Tristate
import Result.Extra
import Task
import Util.DictList as DictList
import Util.Editing as Editing exposing (Editing)
import Util.LensUtil as LensUtil


updateLogic :
    { idOfParent : parent -> parentId
    , toUpdate : parent -> update
    , navigateToAddress : parentId -> List String
    , updateCreationTimestamp : DateUtil.Timestamp -> creation -> creation
    , create : AuthorizedAccess -> creation -> Cmd (Page.LogicMsg parentId parent creation update)
    , save : AuthorizedAccess -> parentId -> update -> Cmd (Page.LogicMsg parentId parent creation update)
    , delete : AuthorizedAccess -> parentId -> Cmd (Page.LogicMsg parentId parent creation update)
    , duplicate : AuthorizedAccess -> parentId -> DateUtil.Timestamp -> Cmd (Page.LogicMsg parentId parent creation update)

    -- todo: This is a workaround. Technically, one should separate those steps that are needed for the initial fetch
    -- from everything else. This is evident in the Meals case now, because one seems to require a profile id, which
    -- should come from the fetched profile, which in turn may be still in the fetching state.
    -- However, in reality the profileId is only necessary for the actual editing functions, which are irrelevant
    -- for the initialization.
    , attemptInitialToMainAfterFetchResponse : Bool
    }
    -> Page.LogicMsg parentId parent creation update
    -> Page.Model parentId parent creation update
    -> ( Page.Model parentId parent creation update, Cmd (Page.LogicMsg parentId parent creation update) )
updateLogic ps msg model =
    let
        onFetch =
            if ps.attemptInitialToMainAfterFetchResponse then
                Tristate.fromInitToMain Page.initialToMain

            else
                identity

        gotFetchResponse result =
            ( result
                |> Result.Extra.unpack (Tristate.toError model)
                    (\parents ->
                        model
                            |> Tristate.mapInitial
                                (Page.lenses.initial.parents.set
                                    (parents
                                        |> List.map Editing.asView
                                        |> DictList.fromListWithKey (.original >> ps.idOfParent)
                                        |> Just
                                    )
                                )
                            |> onFetch
                    )
            , Cmd.none
            )

        finishUpdateCreation creation =
            ( model
                |> Tristate.mapMain (Page.lenses.main.parentCreation.set creation)
            , Cmd.none
            )

        -- The timestamp is only set if there is no current creation.
        prepareUpdateCreation creation =
            model
                |> Tristate.lenses.main.getOption
                |> Maybe.andThen Page.lenses.main.parentCreation.get
                |> Maybe.Extra.unwrap
                    ( model
                    , DateUtil.now
                        |> Task.map (\timestamp -> creation |> Maybe.map (ps.updateCreationTimestamp timestamp))
                        |> Task.perform Page.FinishUpdateCreation
                    )
                    (\_ ->
                        finishUpdateCreation creation
                    )

        create =
            ( model
            , model
                |> Tristate.lenses.main.getOption
                |> Maybe.andThen
                    (\main ->
                        main.parentCreation
                            |> Maybe.map
                                (ps.create
                                    { configuration = model.configuration
                                    , jwt = main.jwt
                                    }
                                )
                    )
                |> Maybe.withDefault Cmd.none
            )

        gotCreationResponseWith params result =
            result
                |> Result.Extra.unpack (\error -> ( Tristate.toError model error, Cmd.none ))
                    (\parent ->
                        let
                            parentId =
                                parent |> ps.idOfParent

                            parentCreationHandling =
                                if params.resetParentCreation then
                                    Page.lenses.main.parentCreation.set Nothing

                                else
                                    identity
                        in
                        ( model
                            |> Tristate.mapMain
                                (LensUtil.insertAtId parentId
                                    Page.lenses.main.parents
                                    (parent |> Editing.asView)
                                    >> parentCreationHandling
                                )
                        , parentId
                            |> ps.navigateToAddress
                            |> Links.loadFrontendPage
                        )
                    )

        gotCreateResponse =
            gotCreationResponseWith { resetParentCreation = True }

        edit parentId update =
            ( model
                |> mapParentStateById parentId
                    (Editing.lenses.update.set update)
            , Cmd.none
            )

        saveEdit parentId =
            ( model
            , model
                |> Tristate.foldMain Cmd.none
                    (\main ->
                        main
                            |> Page.lenses.main.parents.get
                            |> DictList.get parentId
                            |> Maybe.andThen Editing.extractUpdate
                            |> Maybe.Extra.unwrap
                                Cmd.none
                                (ps.save
                                    { configuration = model.configuration
                                    , jwt = main.jwt
                                    }
                                    parentId
                                )
                    )
            )

        gotSaveEditResponse result =
            ( result
                |> Result.Extra.unpack (Tristate.toError model)
                    (\parent ->
                        model
                            |> mapParentStateById (parent |> ps.idOfParent)
                                (Editing.asViewWithElement parent)
                    )
            , Cmd.none
            )

        toggleControls parentId =
            ( model
                |> mapParentStateById parentId Editing.toggleControls
            , Cmd.none
            )

        enterEdit parentId =
            ( model
                |> mapParentStateById parentId (Editing.toUpdate ps.toUpdate)
            , Cmd.none
            )

        exitEdit parentId =
            ( model |> mapParentStateById parentId Editing.toView
            , Cmd.none
            )

        requestDelete parentId =
            ( model |> mapParentStateById parentId Editing.toDelete
            , Cmd.none
            )

        confirmDelete parentId =
            ( model
            , model
                |> Tristate.foldMain Cmd.none
                    (\main ->
                        ps.delete
                            { configuration = model.configuration
                            , jwt = main.jwt
                            }
                            parentId
                    )
            )

        cancelDelete parentId =
            ( model |> mapParentStateById parentId Editing.toView
            , Cmd.none
            )

        gotDeleteResponse deletedId result =
            ( result
                |> Result.Extra.unpack (Tristate.toError model)
                    (always
                        (model
                            |> Tristate.mapMain (LensUtil.deleteAtId deletedId Page.lenses.main.parents)
                        )
                    )
            , Cmd.none
            )

        prepareDuplicate parentId =
            ( model
            , DateUtil.now
                |> Task.perform (Page.GotDuplicateTimestamp parentId)
            )

        gotDuplicateTimestamp parentId timestamp =
            ( model
            , model
                |> Tristate.foldMain Cmd.none
                    (\main ->
                        ps.duplicate
                            { configuration = model.configuration
                            , jwt = main.jwt
                            }
                            parentId
                            timestamp
                    )
            )

        gotDuplicateResponse =
            gotCreationResponseWith { resetParentCreation = False }

        setPagination pagination =
            ( model
                |> Tristate.mapMain (Page.lenses.main.pagination.set pagination)
            , Cmd.none
            )

        setSearchString string =
            ( model
                |> Tristate.mapMain
                    (PaginationSettings.setSearchStringAndReset
                        { searchStringLens =
                            Page.lenses.main.searchString
                        , paginationSettingsLens =
                            Page.lenses.main.pagination
                                |> Compose.lensWithLens Pagination.lenses.parents
                        }
                        string
                    )
            , Cmd.none
            )
    in
    case msg of
        Page.UpdateCreation creation ->
            prepareUpdateCreation creation

        Page.Create ->
            create

        Page.FinishUpdateCreation creation ->
            finishUpdateCreation creation

        Page.GotCreateResponse result ->
            gotCreateResponse result

        Page.Edit parentId update ->
            edit parentId update

        Page.SaveEdit parentId ->
            saveEdit parentId

        Page.GotSaveEditResponse result ->
            gotSaveEditResponse result

        Page.ToggleControls parentId ->
            toggleControls parentId

        Page.EnterEdit parentId ->
            enterEdit parentId

        Page.ExitEdit parentId ->
            exitEdit parentId

        Page.RequestDelete parentId ->
            requestDelete parentId

        Page.ConfirmDelete parentId ->
            confirmDelete parentId

        Page.CancelDelete parentId ->
            cancelDelete parentId

        Page.GotDeleteResponse parentId result ->
            gotDeleteResponse parentId result

        Page.GotFetchResponse result ->
            gotFetchResponse result

        Page.Duplicate parentId ->
            prepareDuplicate parentId

        Page.GotDuplicateTimestamp parentId posix ->
            gotDuplicateTimestamp parentId posix

        Page.GotDuplicateResponse result ->
            gotDuplicateResponse result

        Page.SetPagination pagination ->
            setPagination pagination

        Page.SetSearchString string ->
            setSearchString string


mapParentStateById : parentId -> (Editing parent update -> Editing parent update) -> Page.Model parentId parent creation update -> Page.Model parentId parent creation update
mapParentStateById parentId =
    LensUtil.updateById parentId Page.lenses.main.parents
        >> Tristate.mapMain
