module Pages.ReferenceEntries.Requests exposing
    ( addReferenceEntry
    , deleteReferenceEntry
    , fetchNutrients
    , fetchReferenceEntries
    , fetchReferenceMap
    , saveReferenceEntry
    )

import Addresses.Backend
import Api.Auxiliary exposing (JWT, NutrientCode, ReferenceMapId)
import Api.Types.Nutrient exposing (decoderNutrient)
import Api.Types.ReferenceEntry exposing (ReferenceEntry, decoderReferenceEntry)
import Api.Types.ReferenceEntryCreation exposing (ReferenceEntryCreation, encoderReferenceEntryCreation)
import Api.Types.ReferenceEntryUpdate exposing (ReferenceEntryUpdate, encoderReferenceEntryUpdate)
import Api.Types.ReferenceMap exposing (decoderReferenceMap)
import Http
import Json.Decode as Decode
import Pages.ReferenceEntries.Page as Page exposing (Msg(..))
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil as HttpUtil


fetchReferenceEntries : AuthorizedAccess -> ReferenceMapId -> Cmd Page.Msg
fetchReferenceEntries authorizedAccess referenceMapId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.references.entries.allOf referenceMapId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson GotFetchReferenceEntriesResponse (Decode.list decoderReferenceEntry)
        }


fetchNutrients : AuthorizedAccess -> Cmd Page.Msg
fetchNutrients authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.stats.nutrients
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson GotFetchNutrientsResponse (Decode.list decoderNutrient)
        }


fetchReferenceMap : AuthorizedAccess -> ReferenceMapId -> Cmd Page.Msg
fetchReferenceMap authorizedAccess referenceMapId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.references.single referenceMapId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson GotFetchReferenceMapResponse decoderReferenceMap
        }


saveReferenceEntry : AuthorizedAccess -> ReferenceEntryUpdate -> Cmd Page.Msg
saveReferenceEntry authorizedAccess referenceEntryUpdate =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.references.entries.update
        { body = encoderReferenceEntryUpdate referenceEntryUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson GotSaveReferenceEntryResponse decoderReferenceEntry
        }


deleteReferenceEntry : AuthorizedAccess -> ReferenceMapId -> NutrientCode -> Cmd Page.Msg
deleteReferenceEntry authorizedAccess referenceMapId nutrientCode =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.references.entries.delete referenceMapId nutrientCode)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (GotDeleteReferenceEntryResponse nutrientCode)
        }


addReferenceEntry : AuthorizedAccess -> ReferenceEntryCreation -> Cmd Page.Msg
addReferenceEntry authorizedAccess referenceNutrientCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.references.entries.create
        { body = encoderReferenceEntryCreation referenceNutrientCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson GotAddReferenceEntryResponse decoderReferenceEntry
        }
