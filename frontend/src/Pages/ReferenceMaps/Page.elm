module Pages.ReferenceMaps.Page exposing (..)

import Api.Auxiliary exposing (JWT, ReferenceMapId)
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Dict exposing (Dict)
import Either exposing (Either)
import Monocle.Lens exposing (Lens)
import Pages.ReferenceMaps.Pagination exposing (Pagination)
import Pages.ReferenceMaps.ReferenceMapCreationClientInput exposing (ReferenceMapCreationClientInput)
import Pages.ReferenceMaps.ReferenceMapUpdateClientInput exposing (ReferenceMapUpdateClientInput)
import Pages.ReferenceMaps.Status exposing (Status)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.Editing exposing (Editing)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , referenceMaps : ReferenceMapOrUpdateMap
    , referenceMapToAdd : Maybe ReferenceMapCreationClientInput
    , initialization : Initialization Status
    , pagination : Pagination
    }


type alias ReferenceMapOrUpdate =
    Either ReferenceMap (Editing ReferenceMap ReferenceMapUpdateClientInput)


type alias ReferenceMapOrUpdateMap =
    Dict ReferenceMapId ReferenceMapOrUpdate


lenses :
    { referenceMaps : Lens Model ReferenceMapOrUpdateMap
    , referenceMapToAdd : Lens Model (Maybe ReferenceMapCreationClientInput)
    , initialization : Lens Model (Initialization Status)
    , pagination : Lens Model Pagination
    }
lenses =
    { referenceMaps = Lens .referenceMaps (\b a -> { a | referenceMaps = b })
    , referenceMapToAdd = Lens .referenceMapToAdd (\b a -> { a | referenceMapToAdd = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , pagination = Lens .pagination (\b a -> { a | pagination = b })
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type Msg
    = UpdateReferenceMapCreation (Maybe ReferenceMapCreationClientInput)
    | CreateReferenceMap
    | GotCreateReferenceMapResponse (Result Error ReferenceMap)
    | UpdateReferenceMap ReferenceMapUpdateClientInput
    | SaveReferenceMapEdit ReferenceMapId
    | GotSaveReferenceMapResponse (Result Error ReferenceMap)
    | EnterEditReferenceMap ReferenceMapId
    | ExitEditReferenceMapAt ReferenceMapId
    | DeleteReferenceMap ReferenceMapId
    | GotDeleteReferenceMapResponse ReferenceMapId (Result Error ())
    | GotFetchReferenceMapsResponse (Result Error (List ReferenceMap))
    | SetPagination Pagination
