module Pages.ReferenceMaps.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT, ReferenceMapId)
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Basics.Extra exposing (flip)
import Dict
import Either exposing (Either(..))
import Maybe.Extra
import Monocle.Lens as Lens
import Monocle.Optional
import Pages.ReferenceMaps.Page as Page exposing (ReferenceMapOrUpdate)
import Pages.ReferenceMaps.Pagination as Pagination exposing (Pagination)
import Pages.ReferenceMaps.ReferenceMapCreationClientInput as ReferenceMapCreationClientInput exposing (ReferenceMapCreationClientInput)
import Pages.ReferenceMaps.ReferenceMapUpdateClientInput as ReferenceMapUpdateClientInput exposing (ReferenceMapUpdateClientInput)
import Pages.ReferenceMaps.Requests as Requests
import Pages.ReferenceMaps.Status as Status
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization as Initialization exposing (Initialization(..))
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , referenceMaps = Dict.empty
      , referenceMapToAdd = Nothing
      , initialization = Initialization.Loading Status.initial
      , pagination = Pagination.initial
      }
    , Requests.fetchReferenceMaps flags.authorizedAccess
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.UpdateReferenceMapCreation referenceMapCreationClientInput ->
            updateReferenceMapCreation model referenceMapCreationClientInput

        Page.CreateReferenceMap ->
            createReferenceMap model

        Page.GotCreateReferenceMapResponse dataOrError ->
            gotCreateReferenceMapResponse model dataOrError

        Page.UpdateReferenceMap referenceMapUpdate ->
            updateReferenceMap model referenceMapUpdate

        Page.SaveReferenceMapEdit referenceMapId ->
            saveReferenceMapEdit model referenceMapId

        Page.GotSaveReferenceMapResponse dataOrError ->
            gotSaveReferenceMapResponse model dataOrError

        Page.EnterEditReferenceMap referenceMapId ->
            enterEditReferenceMap model referenceMapId

        Page.ExitEditReferenceMapAt referenceMapId ->
            exitEditReferenceMapAt model referenceMapId

        Page.DeleteReferenceMap referenceMapId ->
            deleteReferenceMap model referenceMapId

        Page.GotDeleteReferenceMapResponse deletedId dataOrError ->
            gotDeleteReferenceMapResponse model deletedId dataOrError

        Page.GotFetchReferenceMapsResponse dataOrError ->
            gotFetchReferenceMapsResponse model dataOrError

        Page.SetPagination pagination ->
            setPagination model pagination


updateReferenceMapCreation : Page.Model -> Maybe ReferenceMapCreationClientInput -> ( Page.Model, Cmd Page.Msg )
updateReferenceMapCreation model referenceMapToAdd =
    ( model
        |> Page.lenses.referenceMapToAdd.set referenceMapToAdd
    , Cmd.none
    )


createReferenceMap : Page.Model -> ( Page.Model, Cmd Page.Msg )
createReferenceMap model =
    ( model
    , model.referenceMapToAdd
        |> Maybe.Extra.unwrap Cmd.none (ReferenceMapCreationClientInput.toCreation >> Requests.createReferenceMap model.authorizedAccess)
    )


gotCreateReferenceMapResponse : Page.Model -> Result Error ReferenceMap -> ( Page.Model, Cmd Page.Msg )
gotCreateReferenceMapResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\referenceMap ->
                model
                    |> Lens.modify Page.lenses.referenceMaps
                        (Dict.insert referenceMap.id (Left referenceMap))
                    |> Page.lenses.referenceMapToAdd.set Nothing
            )
    , Cmd.none
    )


updateReferenceMap : Page.Model -> ReferenceMapUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
updateReferenceMap model referenceMapUpdate =
    ( model
        |> mapReferenceMapOrUpdateById referenceMapUpdate.id
            (Either.mapRight (Editing.lenses.update.set referenceMapUpdate))
    , Cmd.none
    )


saveReferenceMapEdit : Page.Model -> ReferenceMapId -> ( Page.Model, Cmd Page.Msg )
saveReferenceMapEdit model referenceMapId =
    ( model
    , model
        |> Page.lenses.referenceMaps.get
        |> Dict.get referenceMapId
        |> Maybe.andThen Either.rightToMaybe
        |> Maybe.Extra.unwrap
            Cmd.none
            (.update
                >> ReferenceMapUpdateClientInput.to
                >> Requests.saveReferenceMap model.authorizedAccess
            )
    )


gotSaveReferenceMapResponse : Page.Model -> Result Error ReferenceMap -> ( Page.Model, Cmd Page.Msg )
gotSaveReferenceMapResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\referenceMap ->
                model
                    |> mapReferenceMapOrUpdateById referenceMap.id
                        (Either.andThenRight (always (Left referenceMap)))
            )
    , Cmd.none
    )


enterEditReferenceMap : Page.Model -> ReferenceMapId -> ( Page.Model, Cmd Page.Msg )
enterEditReferenceMap model referenceMapId =
    ( model
        |> mapReferenceMapOrUpdateById referenceMapId
            (Either.unpack (\referenceMap -> { original = referenceMap, update = ReferenceMapUpdateClientInput.from referenceMap }) identity >> Right)
    , Cmd.none
    )


exitEditReferenceMapAt : Page.Model -> ReferenceMapId -> ( Page.Model, Cmd Page.Msg )
exitEditReferenceMapAt model referenceMapId =
    ( model |> mapReferenceMapOrUpdateById referenceMapId (Either.andThen (.original >> Left))
    , Cmd.none
    )


deleteReferenceMap : Page.Model -> ReferenceMapId -> ( Page.Model, Cmd Page.Msg )
deleteReferenceMap model referenceMapId =
    ( model
    , Requests.deleteReferenceMap model.authorizedAccess referenceMapId
    )


gotDeleteReferenceMapResponse : Page.Model -> ReferenceMapId -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteReferenceMapResponse model deletedId dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (always
                (model
                    |> Lens.modify Page.lenses.referenceMaps
                        (Dict.remove deletedId)
                )
            )
    , Cmd.none
    )


gotFetchReferenceMapsResponse : Page.Model -> Result Error (List ReferenceMap) -> ( Page.Model, Cmd Page.Msg )
gotFetchReferenceMapsResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\referenceMaps ->
                model
                    |> Page.lenses.referenceMaps.set (referenceMaps |> List.map (\r -> ( r.id, Left r )) |> Dict.fromList)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.referenceMaps).set True
            )
    , Cmd.none
    )


setPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setPagination model pagination =
    ( model |> Page.lenses.pagination.set pagination
    , Cmd.none
    )


mapReferenceMapOrUpdateById : ReferenceMapId -> (Page.ReferenceMapOrUpdate -> Page.ReferenceMapOrUpdate) -> Page.Model -> Page.Model
mapReferenceMapOrUpdateById referenceMapId =
    Page.lenses.referenceMaps
        |> LensUtil.updateById referenceMapId


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
