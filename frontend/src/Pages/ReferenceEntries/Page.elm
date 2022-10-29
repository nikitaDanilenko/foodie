module Pages.ReferenceEntries.Page exposing (..)

import Api.Auxiliary exposing (JWT, NutrientCode, ReferenceMapId)
import Api.Types.Nutrient exposing (Nutrient)
import Api.Types.NutrientUnit as NutrientUnit exposing (NutrientUnit)
import Api.Types.ReferenceEntry exposing (ReferenceEntry)
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Basics.Extra exposing (flip)
import Dict exposing (Dict)
import Either exposing (Either)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.ReferenceEntries.Pagination exposing (Pagination)
import Pages.ReferenceEntries.ReferenceEntryCreationClientInput exposing (ReferenceEntryCreationClientInput)
import Pages.ReferenceEntries.ReferenceEntryUpdateClientInput exposing (ReferenceEntryUpdateClientInput)
import Pages.ReferenceEntries.Status exposing (Status)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.Editing exposing (Editing)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , referenceMapId : ReferenceMapId
    , referenceMap : Maybe ReferenceMap
    , referenceEntries : ReferenceEntryOrUpdateMap
    , nutrients : NutrientMap
    , nutrientsSearchString : String
    , referenceEntriesToAdd : AddNutrientMap
    , initialization : Initialization Status
    , pagination : Pagination
    }


type alias ReferenceEntryOrUpdate =
    Either ReferenceEntry (Editing ReferenceEntry ReferenceEntryUpdateClientInput)


type alias NutrientMap =
    Dict NutrientCode Nutrient


type alias AddNutrientMap =
    Dict NutrientCode ReferenceEntryCreationClientInput


type alias ReferenceEntryOrUpdateMap =
    Dict NutrientCode ReferenceEntryOrUpdate


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , referenceMapId : ReferenceMapId
    }


lenses :
    { referenceMap : Lens Model (Maybe ReferenceMap)
    , referenceEntries : Lens Model ReferenceEntryOrUpdateMap
    , referenceEntriesToAdd : Lens Model AddNutrientMap
    , nutrients : Lens Model NutrientMap
    , nutrientsSearchString : Lens Model String
    , initialization : Lens Model (Initialization Status)
    , pagination : Lens Model Pagination
    }
lenses =
    { referenceMap = Lens .referenceMap (\b a -> { a | referenceMap = b })
    , referenceEntries = Lens .referenceEntries (\b a -> { a | referenceEntries = b })
    , referenceEntriesToAdd = Lens .referenceEntriesToAdd (\b a -> { a | referenceEntriesToAdd = b })
    , nutrients = Lens .nutrients (\b a -> { a | nutrients = b })
    , nutrientsSearchString = Lens .nutrientsSearchString (\b a -> { a | nutrientsSearchString = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , pagination = Lens .pagination (\b a -> { a | pagination = b })
    }


nutrientNameOrEmpty : NutrientMap -> NutrientCode -> String
nutrientNameOrEmpty nutrientMap =
    flip Dict.get nutrientMap >> Maybe.Extra.unwrap "" .name


nutrientUnitOrEmpty : NutrientMap -> NutrientCode -> String
nutrientUnitOrEmpty nutrientMap =
    flip Dict.get nutrientMap >> Maybe.Extra.unwrap "" (.unit >> NutrientUnit.toString)


type Msg
    = UpdateReferenceEntry ReferenceEntryUpdateClientInput
    | SaveReferenceEntryEdit ReferenceEntryUpdateClientInput
    | GotSaveReferenceEntryResponse (Result Error ReferenceEntry)
    | EnterEditReferenceEntry NutrientCode
    | ExitEditReferenceEntryAt NutrientCode
    | DeleteReferenceEntry NutrientCode
    | GotDeleteReferenceEntryResponse NutrientCode (Result Error ())
    | GotFetchReferenceEntriesResponse (Result Error (List ReferenceEntry))
    | GotFetchReferenceMapResponse (Result Error ReferenceMap)
    | GotFetchNutrientsResponse (Result Error (List Nutrient))
    | SelectNutrient NutrientCode
    | DeselectNutrient NutrientCode
    | AddNutrient NutrientCode
    | GotAddReferenceEntryResponse (Result Error ReferenceEntry)
    | UpdateAddNutrient ReferenceEntryCreationClientInput
    | UpdateNutrients String
    | SetNutrientsSearchString String
    | SetPagination Pagination
