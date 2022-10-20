module Pages.ReferenceMaps.Requests exposing (createReferenceMap, deleteReferenceMap, fetchReferenceMaps, saveReferenceMap)

import Addresses.Backend
import Api.Auxiliary exposing (JWT, ReferenceMapId)
import Api.Types.ReferenceMap exposing (ReferenceMap, decoderReferenceMap)
import Api.Types.ReferenceMapCreation exposing (ReferenceMapCreation, encoderReferenceMapCreation)
import Api.Types.ReferenceMapUpdate exposing (ReferenceMapUpdate, encoderReferenceMapUpdate)
import Http
import Json.Decode as Decode
import Pages.ReferenceMaps.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil as HttpUtil


fetchReferenceMaps : AuthorizedAccess -> Cmd Page.Msg
fetchReferenceMaps authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.references.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchReferenceMapsResponse (Decode.list decoderReferenceMap)
        }


createReferenceMap : AuthorizedAccess -> ReferenceMapCreation -> Cmd Page.Msg
createReferenceMap authorizedAccess referenceMapCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.references.create
        { body = encoderReferenceMapCreation referenceMapCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotCreateReferenceMapResponse decoderReferenceMap
        }


saveReferenceMap : AuthorizedAccess -> ReferenceMapUpdate -> Cmd Page.Msg
saveReferenceMap authorizedAccess referenceMapUpdate =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.references.update
        { body = encoderReferenceMapUpdate referenceMapUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotSaveReferenceMapResponse decoderReferenceMap
        }


deleteReferenceMap : AuthorizedAccess -> ReferenceMapId -> Cmd Page.Msg
deleteReferenceMap authorizedAccess referenceMapId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.references.delete referenceMapId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (Page.GotDeleteReferenceMapResponse referenceMapId)
        }
