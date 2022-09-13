module Pages.ReferenceNutrients.Requests exposing
    ( addReferenceNutrient
    , deleteReferenceNutrient
    , fetchNutrients
    , fetchReferenceNutrients
    , saveReferenceNutrient
    )

import Api.Auxiliary exposing (JWT, NutrientCode)
import Api.Types.Nutrient exposing (decoderNutrient)
import Api.Types.ReferenceNutrient exposing (ReferenceNutrient, decoderReferenceNutrient)
import Api.Types.ReferenceNutrientCreation exposing (ReferenceNutrientCreation, encoderReferenceNutrientCreation)
import Api.Types.ReferenceNutrientUpdate exposing (ReferenceNutrientUpdate, encoderReferenceNutrientUpdate)
import Configuration exposing (Configuration)
import Json.Decode as Decode
import Pages.ReferenceNutrients.Page as Page exposing (Msg(..))
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Url.Builder
import Util.HttpUtil as HttpUtil


fetchReferenceNutrients : FlagsWithJWT -> Cmd Page.Msg
fetchReferenceNutrients flags =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "stats", "reference", "all" ] []
        , expect = HttpUtil.expectJson GotFetchReferenceNutrientsResponse (Decode.list decoderReferenceNutrient)
        }


fetchNutrients : FlagsWithJWT -> Cmd Page.Msg
fetchNutrients flags =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "stats", "nutrients" ] []
        , expect = HttpUtil.expectJson GotFetchNutrientsResponse (Decode.list decoderNutrient)
        }


saveReferenceNutrient : FlagsWithJWT -> ReferenceNutrientUpdate -> Cmd Page.Msg
saveReferenceNutrient flags mealEntryUpdate =
    HttpUtil.patchJsonWithJWT
        flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "stats", "reference", "update" ] []
        , body = encoderReferenceNutrientUpdate mealEntryUpdate
        , expect = HttpUtil.expectJson GotSaveReferenceNutrientResponse decoderReferenceNutrient
        }


deleteReferenceNutrient : FlagsWithJWT -> NutrientCode -> Cmd Page.Msg
deleteReferenceNutrient fs nutrientCode =
    HttpUtil.deleteWithJWT fs.jwt
        { url = Url.Builder.relative [ fs.configuration.backendURL, "stats", "reference", "delete", String.fromInt nutrientCode ] []
        , expect = HttpUtil.expectWhatever (GotDeleteReferenceNutrientResponse nutrientCode)
        }


addReferenceNutrient : FlagsWithJWT -> ReferenceNutrientCreation -> Cmd Page.Msg
addReferenceNutrient flags referenceNutrientCreation =
    HttpUtil.postJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "stats", "reference", "create" ] []
        , body = encoderReferenceNutrientCreation referenceNutrientCreation
        , expect = HttpUtil.expectJson GotAddReferenceNutrientResponse decoderReferenceNutrient
        }
