module Pages.ReferenceNutrients.Page exposing (..)

import Api.Auxiliary exposing (JWT, NutrientCode)
import Api.Types.Nutrient exposing (Nutrient)
import Api.Types.NutrientUnit as NutrientUnit exposing (NutrientUnit)
import Api.Types.ReferenceNutrient exposing (ReferenceNutrient)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Dict exposing (Dict)
import Either exposing (Either)
import Http exposing (Error)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.ReferenceNutrients.ReferenceNutrientCreationClientInput exposing (ReferenceNutrientCreationClientInput)
import Pages.ReferenceNutrients.ReferenceNutrientUpdateClientInput exposing (ReferenceNutrientUpdateClientInput)
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Util.Editing as Editing exposing (Editing)


type alias Model =
    { flagsWithJWT : FlagsWithJWT
    , referenceNutrients : List ReferenceNutrientOrUpdate
    , nutrients : NutrientMap
    , nutrientsSearchString : String
    , referenceNutrientsToAdd : List ReferenceNutrientCreationClientInput
    }


type alias ReferenceNutrientOrUpdate =
    Either ReferenceNutrient (Editing ReferenceNutrient ReferenceNutrientUpdateClientInput)


type alias NutrientMap =
    Dict NutrientCode Nutrient


type alias Flags =
    { configuration : Configuration
    , jwt : Maybe JWT
    }


lenses :
    { jwt : Lens Model JWT
    , referenceNutrients : Lens Model (List ReferenceNutrientOrUpdate)
    , referenceNutrientsToAdd : Lens Model (List ReferenceNutrientCreationClientInput)
    , nutrients : Lens Model NutrientMap
    , nutrientsSearchString : Lens Model String
    }
lenses =
    { jwt =
        let
            flagsLens =
                Lens .flagsWithJWT (\b a -> { a | flagsWithJWT = b })

            jwtLens =
                Lens .jwt (\b a -> { a | jwt = b })
        in
        flagsLens |> Compose.lensWithLens jwtLens
    , referenceNutrients = Lens .referenceNutrients (\b a -> { a | referenceNutrients = b })
    , referenceNutrientsToAdd = Lens .referenceNutrientsToAdd (\b a -> { a | referenceNutrientsToAdd = b })
    , nutrients = Lens .nutrients (\b a -> { a | nutrients = b })
    , nutrientsSearchString = Lens .nutrientsSearchString (\b a -> { a | nutrientsSearchString = b })
    }


nutrientNameOrEmpty : NutrientMap -> NutrientCode -> String
nutrientNameOrEmpty nutrientMap =
    flip Dict.get nutrientMap >> Maybe.Extra.unwrap "" .name


nutrientUnitOrEmpty : NutrientMap -> NutrientCode -> String
nutrientUnitOrEmpty nutrientMap =
    flip Dict.get nutrientMap >> Maybe.Extra.unwrap "" (.unit >> NutrientUnit.toString)


nutrientCodeOf : ReferenceNutrientOrUpdate -> NutrientCode
nutrientCodeOf =
    Either.unpack
        .nutrientCode
        (.original >> .nutrientCode)


nutrientCodeIs : NutrientCode -> ReferenceNutrientOrUpdate -> Bool
nutrientCodeIs =
    Editing.is .nutrientCode


type Msg
    = UpdateReferenceNutrient ReferenceNutrientUpdateClientInput
    | SaveReferenceNutrientEdit NutrientCode
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
    | UpdateJWT JWT
    | UpdateNutrients String
    | SetNutrientsSearchString String
