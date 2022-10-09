module Pages.ReferenceNutrients.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT, NutrientCode)
import Api.Types.Nutrient exposing (Nutrient, decoderNutrient, encoderNutrient)
import Api.Types.ReferenceNutrient exposing (ReferenceNutrient)
import Basics.Extra exposing (flip)
import Dict
import Either exposing (Either(..))
import Http exposing (Error)
import Json.Decode as Decode
import Json.Encode as Encode
import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Monocle.Optional as Optional
import Pages.ReferenceNutrients.Page as Page exposing (Msg(..))
import Pages.ReferenceNutrients.Pagination as Pagination exposing (Pagination)
import Pages.ReferenceNutrients.ReferenceNutrientCreationClientInput as ReferenceNutrientCreationClientInput exposing (ReferenceNutrientCreationClientInput)
import Pages.ReferenceNutrients.ReferenceNutrientUpdateClientInput as ReferenceNutrientUpdateClientInput exposing (ReferenceNutrientUpdateClientInput)
import Pages.ReferenceNutrients.Requests as Requests
import Pages.ReferenceNutrients.Status as Status
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Pages.Util.InitUtil as InitUtil
import Ports
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil as HttpUtil
import Util.Initialization as Initialization
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    let
        ( jwt, cmd ) =
            InitUtil.fetchIfEmpty flags.jwt
                (\token ->
                    initialFetch
                        { configuration = flags.configuration
                        , jwt = token
                        }
                )
    in
    ( { flagsWithJWT =
            { configuration = flags.configuration
            , jwt = jwt
            }
      , referenceNutrients = Dict.empty
      , nutrients = Dict.empty
      , nutrientsSearchString = ""
      , referenceNutrientsToAdd = Dict.empty
      , initialization = Initialization.Loading (Status.initial |> Status.lenses.jwt.set (jwt |> String.isEmpty |> not))
      , pagination = Pagination.initial
      }
    , cmd
    )


initialFetch : FlagsWithJWT -> Cmd Page.Msg
initialFetch flags =
    Cmd.batch
        [ Requests.fetchReferenceNutrients flags
        , Ports.doFetchNutrients ()
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.UpdateReferenceNutrient referenceNutrientUpdateClientInput ->
            updateReferenceNutrient model referenceNutrientUpdateClientInput

        Page.SaveReferenceNutrientEdit referenceNutrientUpdateClientInput ->
            saveReferenceNutrientEdit model referenceNutrientUpdateClientInput

        Page.GotSaveReferenceNutrientResponse result ->
            gotSaveReferenceNutrientResponse model result

        Page.EnterEditReferenceNutrient nutrientCode ->
            enterEditReferenceNutrient model nutrientCode

        Page.ExitEditReferenceNutrientAt nutrientCode ->
            exitEditReferenceNutrientAt model nutrientCode

        Page.DeleteReferenceNutrient nutrientCode ->
            deleteReferenceNutrient model nutrientCode

        Page.GotDeleteReferenceNutrientResponse nutrientCode result ->
            gotDeleteReferenceNutrientResponse model nutrientCode result

        Page.GotFetchReferenceNutrientsResponse result ->
            gotFetchReferenceNutrientsResponse model result

        Page.GotFetchNutrientsResponse result ->
            gotFetchNutrientsResponse model result

        Page.SelectNutrient nutrient ->
            selectNutrient model nutrient

        Page.DeselectNutrient nutrientCode ->
            deselectNutrient model nutrientCode

        Page.AddNutrient nutrientCode ->
            addNutrient model nutrientCode

        Page.GotAddReferenceNutrientResponse result ->
            gotAddReferenceNutrientResponse model result

        Page.UpdateAddNutrient referenceNutrientCreationClientInput ->
            updateAddNutrient model referenceNutrientCreationClientInput

        Page.UpdateJWT jwt ->
            updateJWT model jwt

        Page.SetNutrientsSearchString string ->
            setNutrientsSearchString model string

        Page.UpdateNutrients string ->
            updateNutrients model string

        Page.SetPagination pagination ->
            setPagination model pagination


updateReferenceNutrient : Page.Model -> ReferenceNutrientUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
updateReferenceNutrient model referenceNutrientUpdateClientInput =
    ( model
        |> mapReferenceNutrientOrUpdateById referenceNutrientUpdateClientInput.nutrientCode
            (Either.mapRight (Editing.updateLens.set referenceNutrientUpdateClientInput))
    , Cmd.none
    )


saveReferenceNutrientEdit : Page.Model -> ReferenceNutrientUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
saveReferenceNutrientEdit model referenceNutrientUpdateClientInput =
    ( model
    , referenceNutrientUpdateClientInput
        |> ReferenceNutrientUpdateClientInput.to
        |> Requests.saveReferenceNutrient model.flagsWithJWT
    )


gotSaveReferenceNutrientResponse : Page.Model -> Result Error ReferenceNutrient -> ( Page.Model, Cmd Page.Msg )
gotSaveReferenceNutrientResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\referenceNutrient ->
                model
                    |> mapReferenceNutrientOrUpdateById referenceNutrient.nutrientCode
                        (always (Left referenceNutrient))
                    |> Lens.modify Page.lenses.referenceNutrientsToAdd (Dict.remove referenceNutrient.nutrientCode)
            )
    , Cmd.none
    )


enterEditReferenceNutrient : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
enterEditReferenceNutrient model nutrientCode =
    ( model
        |> mapReferenceNutrientOrUpdateById nutrientCode
            (Either.andThenLeft
                (\me ->
                    Right
                        { original = me
                        , update = ReferenceNutrientUpdateClientInput.from me
                        }
                )
            )
    , Cmd.none
    )


exitEditReferenceNutrientAt : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
exitEditReferenceNutrientAt model nutrientCode =
    ( model
        |> mapReferenceNutrientOrUpdateById nutrientCode (Either.andThen (.original >> Left))
    , Cmd.none
    )


deleteReferenceNutrient : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
deleteReferenceNutrient model nutrientCode =
    ( model
    , Requests.deleteReferenceNutrient model.flagsWithJWT nutrientCode
    )


gotDeleteReferenceNutrientResponse : Page.Model -> NutrientCode -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteReferenceNutrientResponse model nutrientCode result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (Lens.modify Page.lenses.referenceNutrients (Dict.remove nutrientCode) model
                |> always
            )
    , Cmd.none
    )


gotFetchReferenceNutrientsResponse : Page.Model -> Result Error (List ReferenceNutrient) -> ( Page.Model, Cmd Page.Msg )
gotFetchReferenceNutrientsResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\referenceNutrients ->
                model
                    |> Page.lenses.referenceNutrients.set (referenceNutrients |> List.map (\r -> ( r.nutrientCode, Left r )) |> Dict.fromList)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.referenceNutrients).set True
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
        |> Lens.modify Page.lenses.referenceNutrientsToAdd
            (Dict.update nutrientCode (always (ReferenceNutrientCreationClientInput.default nutrientCode) >> Just))
    , Cmd.none
    )


deselectNutrient : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
deselectNutrient model nutrientCode =
    ( model
        |> Lens.modify Page.lenses.referenceNutrientsToAdd (Dict.remove nutrientCode)
    , Cmd.none
    )


addNutrient : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
addNutrient model nutrientCode =
    ( model
    , Dict.get nutrientCode model.referenceNutrientsToAdd
        |> Maybe.map
            (ReferenceNutrientCreationClientInput.toCreation
                >> Requests.addReferenceNutrient model.flagsWithJWT
            )
        |> Maybe.withDefault Cmd.none
    )


gotAddReferenceNutrientResponse : Page.Model -> Result Error ReferenceNutrient -> ( Page.Model, Cmd Page.Msg )
gotAddReferenceNutrientResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\referenceNutrient ->
                model
                    |> Lens.modify Page.lenses.referenceNutrients
                        (Dict.update referenceNutrient.nutrientCode (always referenceNutrient >> Left >> Just))
                    |> Lens.modify Page.lenses.referenceNutrientsToAdd (Dict.remove referenceNutrient.nutrientCode)
            )
    , Cmd.none
    )


updateAddNutrient : Page.Model -> ReferenceNutrientCreationClientInput -> ( Page.Model, Cmd Page.Msg )
updateAddNutrient model referenceNutrientCreationClientInput =
    ( model
        |> Lens.modify Page.lenses.referenceNutrientsToAdd
            (Dict.update referenceNutrientCreationClientInput.nutrientCode (always referenceNutrientCreationClientInput >> Just))
    , Cmd.none
    )


updateJWT : Page.Model -> JWT -> ( Page.Model, Cmd Page.Msg )
updateJWT model jwt =
    let
        newModel =
            model
                |> Page.lenses.jwt.set jwt
                |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.jwt).set True
    in
    ( newModel
    , initialFetch newModel.flagsWithJWT
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
                    Requests.fetchNutrients model.flagsWithJWT

                  else
                    Cmd.none
                )
            )


setNutrientsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setNutrientsSearchString model string =
    ( model |> Page.lenses.nutrientsSearchString.set string
    , Cmd.none
    )


setPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setPagination model pagination =
    ( model |> Page.lenses.pagination.set pagination
    , Cmd.none
    )


mapReferenceNutrientOrUpdateById : NutrientCode -> (Page.ReferenceNutrientOrUpdate -> Page.ReferenceNutrientOrUpdate) -> Page.Model -> Page.Model
mapReferenceNutrientOrUpdateById ingredientId =
    Page.lenses.referenceNutrients
        |> Compose.lensWithOptional (LensUtil.dictByKey ingredientId)
        |> Optional.modify


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization


setJsonError : Decode.Error -> Page.Model -> Page.Model
setJsonError =
    HttpUtil.setJsonError Page.lenses.initialization
