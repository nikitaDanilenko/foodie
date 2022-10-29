module Pages.ReferenceEntries.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT, NutrientCode, ReferenceMapId)
import Api.Types.Nutrient exposing (Nutrient, decoderNutrient, encoderNutrient)
import Api.Types.ReferenceEntry exposing (ReferenceEntry)
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Basics.Extra exposing (flip)
import Dict
import Either exposing (Either(..))
import Json.Decode as Decode
import Json.Encode as Encode
import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Monocle.Optional
import Pages.ReferenceEntries.Page as Page exposing (Msg(..))
import Pages.ReferenceEntries.Pagination as Pagination exposing (Pagination)
import Pages.ReferenceEntries.ReferenceEntryCreationClientInput as ReferenceEntryCreationClientInput exposing (ReferenceEntryCreationClientInput)
import Pages.ReferenceEntries.ReferenceEntryUpdateClientInput as ReferenceEntryUpdateClientInput exposing (ReferenceEntryUpdateClientInput)
import Pages.ReferenceEntries.Requests as Requests
import Pages.ReferenceEntries.Status as Status
import Pages.Util.PaginationSettings as PaginationSettings
import Ports
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization as Initialization
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , referenceMapId = flags.referenceMapId
      , referenceMap = Nothing
      , referenceEntries = Dict.empty
      , nutrients = Dict.empty
      , nutrientsSearchString = ""
      , referenceEntriesToAdd = Dict.empty
      , initialization = Initialization.Loading Status.initial
      , pagination = Pagination.initial
      }
    , initialFetch flags
    )


initialFetch : Page.Flags -> Cmd Page.Msg
initialFetch flags =
    Cmd.batch
        [ Requests.fetchReferenceEntries flags.authorizedAccess flags.referenceMapId
        , Requests.fetchReferenceMap flags.authorizedAccess flags.referenceMapId
        , Ports.doFetchNutrients ()
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.UpdateReferenceEntry referenceEntryUpdateClientInput ->
            updateReferenceEntry model referenceEntryUpdateClientInput

        Page.SaveReferenceEntryEdit referenceEntryUpdateClientInput ->
            saveReferenceEntryEdit model referenceEntryUpdateClientInput

        Page.GotSaveReferenceEntryResponse result ->
            gotSaveReferenceEntryResponse model result

        Page.EnterEditReferenceEntry nutrientCode ->
            enterEditReferenceEntry model nutrientCode

        Page.ExitEditReferenceEntryAt nutrientCode ->
            exitEditReferenceEntryAt model nutrientCode

        Page.DeleteReferenceEntry nutrientCode ->
            deleteReferenceEntry model nutrientCode

        Page.GotDeleteReferenceEntryResponse nutrientCode result ->
            gotDeleteReferenceEntryResponse model nutrientCode result

        Page.GotFetchReferenceEntriesResponse result ->
            gotFetchReferenceEntriesResponse model result

        Page.GotFetchReferenceMapResponse result ->
            gotFetchReferenceMapResponse model result

        Page.GotFetchNutrientsResponse result ->
            gotFetchNutrientsResponse model result

        Page.SelectNutrient nutrient ->
            selectNutrient model nutrient

        Page.DeselectNutrient nutrientCode ->
            deselectNutrient model nutrientCode

        Page.AddNutrient nutrientCode ->
            addNutrient model nutrientCode

        Page.GotAddReferenceEntryResponse result ->
            gotAddReferenceEntryResponse model result

        Page.UpdateAddNutrient referenceEntryCreationClientInput ->
            updateAddNutrient model referenceEntryCreationClientInput

        Page.SetNutrientsSearchString string ->
            setNutrientsSearchString model string

        Page.UpdateNutrients string ->
            updateNutrients model string

        Page.SetPagination pagination ->
            setPagination model pagination


updateReferenceEntry : Page.Model -> ReferenceEntryUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
updateReferenceEntry model referenceEntryUpdateClientInput =
    ( model
        |> mapReferenceEntryOrUpdateById referenceEntryUpdateClientInput.nutrientCode
            (Either.mapRight (Editing.lenses.update.set referenceEntryUpdateClientInput))
    , Cmd.none
    )


saveReferenceEntryEdit : Page.Model -> ReferenceEntryUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
saveReferenceEntryEdit model referenceEntryUpdateClientInput =
    ( model
    , referenceEntryUpdateClientInput
        |> ReferenceEntryUpdateClientInput.to model.referenceMapId
        |> Requests.saveReferenceEntry model.authorizedAccess
    )


gotSaveReferenceEntryResponse : Page.Model -> Result Error ReferenceEntry -> ( Page.Model, Cmd Page.Msg )
gotSaveReferenceEntryResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\referenceEntry ->
                model
                    |> mapReferenceEntryOrUpdateById referenceEntry.nutrientCode
                        (always (Left referenceEntry))
                    |> Lens.modify Page.lenses.referenceEntriesToAdd (Dict.remove referenceEntry.nutrientCode)
            )
    , Cmd.none
    )


enterEditReferenceEntry : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
enterEditReferenceEntry model nutrientCode =
    ( model
        |> mapReferenceEntryOrUpdateById nutrientCode
            (Either.andThenLeft
                (\me ->
                    Right
                        { original = me
                        , update = ReferenceEntryUpdateClientInput.from me
                        }
                )
            )
    , Cmd.none
    )


exitEditReferenceEntryAt : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
exitEditReferenceEntryAt model nutrientCode =
    ( model
        |> mapReferenceEntryOrUpdateById nutrientCode (Either.andThen (.original >> Left))
    , Cmd.none
    )


deleteReferenceEntry : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
deleteReferenceEntry model nutrientCode =
    ( model
    , Requests.deleteReferenceEntry model.authorizedAccess model.referenceMapId nutrientCode
    )


gotDeleteReferenceEntryResponse : Page.Model -> NutrientCode -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteReferenceEntryResponse model nutrientCode result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (Lens.modify Page.lenses.referenceEntries (Dict.remove nutrientCode) model
                |> always
            )
    , Cmd.none
    )


gotFetchReferenceEntriesResponse : Page.Model -> Result Error (List ReferenceEntry) -> ( Page.Model, Cmd Page.Msg )
gotFetchReferenceEntriesResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\referenceEntries ->
                model
                    |> Page.lenses.referenceEntries.set (referenceEntries |> List.map (\r -> ( r.nutrientCode, Left r )) |> Dict.fromList)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.referenceEntries).set True
            )
    , Cmd.none
    )


gotFetchReferenceMapResponse : Page.Model -> Result Error ReferenceMap -> ( Page.Model, Cmd Page.Msg )
gotFetchReferenceMapResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\referenceMap ->
                model
                    |> Page.lenses.referenceMap.set (Just referenceMap)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.referenceMap).set True
            )
    , Cmd.none
    )


gotFetchNutrientsResponse : Page.Model -> Result Error (List Nutrient) -> ( Page.Model, Cmd Page.Msg )
gotFetchNutrientsResponse model result =
    result
        |> Either.fromResult
        |> Either.unpack (\error -> ( setError error model, Cmd.none ))
            (\nutrients ->
                ( model
                    |> LensUtil.set nutrients .code Page.lenses.nutrients
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.nutrients).set True
                , nutrients
                    |> Encode.list encoderNutrient
                    |> Encode.encode 0
                    |> Ports.storeNutrients
                )
            )


selectNutrient : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
selectNutrient model nutrientCode =
    ( model
        |> Lens.modify Page.lenses.referenceEntriesToAdd
            (Dict.update nutrientCode (always (ReferenceEntryCreationClientInput.default nutrientCode) >> Just))
    , Cmd.none
    )


deselectNutrient : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
deselectNutrient model nutrientCode =
    ( model
        |> Lens.modify Page.lenses.referenceEntriesToAdd (Dict.remove nutrientCode)
    , Cmd.none
    )


addNutrient : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
addNutrient model nutrientCode =
    ( model
    , Dict.get nutrientCode model.referenceEntriesToAdd
        |> Maybe.map
            (ReferenceEntryCreationClientInput.toCreation model.referenceMapId
                >> Requests.addReferenceEntry model.authorizedAccess
            )
        |> Maybe.withDefault Cmd.none
    )


gotAddReferenceEntryResponse : Page.Model -> Result Error ReferenceEntry -> ( Page.Model, Cmd Page.Msg )
gotAddReferenceEntryResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\referenceEntry ->
                model
                    |> Lens.modify Page.lenses.referenceEntries
                        (Dict.update referenceEntry.nutrientCode (always referenceEntry >> Left >> Just))
                    |> Lens.modify Page.lenses.referenceEntriesToAdd (Dict.remove referenceEntry.nutrientCode)
            )
    , Cmd.none
    )


updateAddNutrient : Page.Model -> ReferenceEntryCreationClientInput -> ( Page.Model, Cmd Page.Msg )
updateAddNutrient model referenceEntryCreationClientInput =
    ( model
        |> Lens.modify Page.lenses.referenceEntriesToAdd
            (Dict.update referenceEntryCreationClientInput.nutrientCode (always referenceEntryCreationClientInput >> Just))
    , Cmd.none
    )


updateNutrients : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
updateNutrients model =
    Decode.decodeString (Decode.list decoderNutrient)
        >> Either.fromResult
        >> Either.unpack (\error -> ( setJsonError error model, Cmd.none ))
            (\nutrients ->
                ( model
                    |> LensUtil.set nutrients .code Page.lenses.nutrients
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.nutrients).set
                        (nutrients
                            |> List.isEmpty
                            |> not
                        )
                , if List.isEmpty nutrients then
                    Requests.fetchNutrients model.authorizedAccess

                  else
                    Cmd.none
                )
            )


setNutrientsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setNutrientsSearchString model string =
    ( PaginationSettings.setSearchStringAndReset
        { searchStringLens =
            Page.lenses.nutrientsSearchString
        , paginationSettingsLens =
            Page.lenses.pagination
                |> Compose.lensWithLens Pagination.lenses.nutrients
        }
        model
        string
    , Cmd.none
    )


setPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setPagination model pagination =
    ( model |> Page.lenses.pagination.set pagination
    , Cmd.none
    )


mapReferenceEntryOrUpdateById : NutrientCode -> (Page.ReferenceEntryOrUpdate -> Page.ReferenceEntryOrUpdate) -> Page.Model -> Page.Model
mapReferenceEntryOrUpdateById ingredientId =
    Page.lenses.referenceEntries
        |> LensUtil.updateById ingredientId


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization


setJsonError : Decode.Error -> Page.Model -> Page.Model
setJsonError =
    HttpUtil.setJsonError Page.lenses.initialization
