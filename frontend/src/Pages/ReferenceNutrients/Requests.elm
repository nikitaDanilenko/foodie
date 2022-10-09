module Pages.ReferenceNutrients.Requests exposing
    ( addReferenceNutrient
    , deleteReferenceNutrient
    , fetchNutrients
    , fetchReferenceNutrients
    , saveReferenceNutrient
    )

import Addresses.Backend
import Api.Auxiliary exposing (JWT, NutrientCode)
import Api.Types.Nutrient exposing (decoderNutrient)
import Api.Types.ReferenceNutrient exposing (ReferenceNutrient, decoderReferenceNutrient)
import Api.Types.ReferenceNutrientCreation exposing (ReferenceNutrientCreation, encoderReferenceNutrientCreation)
import Api.Types.ReferenceNutrientUpdate exposing (ReferenceNutrientUpdate, encoderReferenceNutrientUpdate)
import Http
import Json.Decode as Decode
import Pages.ReferenceNutrients.Page as Page exposing (Msg(..))
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Util.HttpUtil as HttpUtil


fetchReferenceNutrients : FlagsWithJWT -> Cmd Page.Msg
fetchReferenceNutrients flags =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.stats.references.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson GotFetchReferenceNutrientsResponse (Decode.list decoderReferenceNutrient)
        }


fetchNutrients : FlagsWithJWT -> Cmd Page.Msg
fetchNutrients flags =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.stats.nutrients
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson GotFetchNutrientsResponse (Decode.list decoderNutrient)
        }


saveReferenceNutrient : FlagsWithJWT -> ReferenceNutrientUpdate -> Cmd Page.Msg
saveReferenceNutrient flags mealEntryUpdate =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.stats.references.update
        { body = encoderReferenceNutrientUpdate mealEntryUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson GotSaveReferenceNutrientResponse decoderReferenceNutrient
        }


deleteReferenceNutrient : FlagsWithJWT -> NutrientCode -> Cmd Page.Msg
deleteReferenceNutrient flags nutrientCode =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.stats.references.delete nutrientCode)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (GotDeleteReferenceNutrientResponse nutrientCode)
        }


addReferenceNutrient : FlagsWithJWT -> ReferenceNutrientCreation -> Cmd Page.Msg
addReferenceNutrient flags referenceNutrientCreation =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.stats.references.create
        { body = encoderReferenceNutrientCreation referenceNutrientCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson GotAddReferenceNutrientResponse decoderReferenceNutrient
        }
