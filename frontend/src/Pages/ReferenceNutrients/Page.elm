module Pages.ReferenceNutrients.Page exposing (..)

import Api.Auxiliary exposing (JWT, NutrientCode)
import Api.Types.Nutrient exposing (Nutrient)
import Api.Types.NutrientUnit as NutrientUnit exposing (NutrientUnit)
import Api.Types.ReferenceNutrient exposing (ReferenceNutrient)
import Basics.Extra exposing (flip)
import Dict exposing (Dict)
import Either exposing (Either)
import Http exposing (Error)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.ReferenceNutrients.Pagination exposing (Pagination)
import Pages.ReferenceNutrients.ReferenceNutrientCreationClientInput exposing (ReferenceNutrientCreationClientInput)
import Pages.ReferenceNutrients.ReferenceNutrientUpdateClientInput exposing (ReferenceNutrientUpdateClientInput)
import Pages.ReferenceNutrients.Status exposing (Status)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.Editing exposing (Editing)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , referenceNutrients : ReferenceNutrientOrUpdateMap
    , nutrients : NutrientMap
    , nutrientsSearchString : String
    , referenceNutrientsToAdd : AddNutrientMap
    , initialization : Initialization Status
    , pagination : Pagination
    }


type alias ReferenceNutrientOrUpdate =
    Either ReferenceNutrient (Editing ReferenceNutrient ReferenceNutrientUpdateClientInput)


type alias NutrientMap =
    Dict NutrientCode Nutrient


type alias AddNutrientMap =
    Dict NutrientCode ReferenceNutrientCreationClientInput


type alias ReferenceNutrientOrUpdateMap =
    Dict NutrientCode ReferenceNutrientOrUpdate


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


lenses :
    { referenceNutrients : Lens Model ReferenceNutrientOrUpdateMap
    , referenceNutrientsToAdd : Lens Model AddNutrientMap
    , nutrients : Lens Model NutrientMap
    , nutrientsSearchString : Lens Model String
    , initialization : Lens Model (Initialization Status)
    , pagination : Lens Model Pagination
    }
lenses =
    { referenceNutrients = Lens .referenceNutrients (\b a -> { a | referenceNutrients = b })
    , referenceNutrientsToAdd = Lens .referenceNutrientsToAdd (\b a -> { a | referenceNutrientsToAdd = b })
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
    = UpdateReferenceNutrient ReferenceNutrientUpdateClientInput
    | SaveReferenceNutrientEdit ReferenceNutrientUpdateClientInput
    | GotSaveReferenceNutrientResponse (Result Error ReferenceNutrient)
    | EnterEditReferenceNutrient NutrientCode
    | ExitEditReferenceNutrientAt NutrientCode
    | DeleteReferenceNutrient NutrientCode
    | GotDeleteReferenceNutrientResponse NutrientCode (Result Error ())
    | GotFetchReferenceNutrientsResponse (Result Error (List ReferenceNutrient))
    | GotFetchNutrientsResponse (Result Error (List Nutrient))
    | SelectNutrient NutrientCode
    | DeselectNutrient NutrientCode
    | AddNutrient NutrientCode
    | GotAddReferenceNutrientResponse (Result Error ReferenceNutrient)
    | UpdateAddNutrient ReferenceNutrientCreationClientInput
    | UpdateNutrients String
    | SetNutrientsSearchString String
    | SetPagination Pagination
