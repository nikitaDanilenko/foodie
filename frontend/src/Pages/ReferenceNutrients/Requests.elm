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
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil as HttpUtil


fetchReferenceNutrients : AuthorizedAccess -> Cmd Page.Msg
fetchReferenceNutrients authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.stats.references.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson GotFetchReferenceNutrientsResponse (Decode.list decoderReferenceNutrient)
        }


fetchNutrients : AuthorizedAccess -> Cmd Page.Msg
fetchNutrients authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.stats.nutrients
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson GotFetchNutrientsResponse (Decode.list decoderNutrient)
        }


saveReferenceNutrient : AuthorizedAccess -> ReferenceNutrientUpdate -> Cmd Page.Msg
saveReferenceNutrient authorizedAccess mealEntryUpdate =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.stats.references.update
        { body = encoderReferenceNutrientUpdate mealEntryUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson GotSaveReferenceNutrientResponse decoderReferenceNutrient
        }


deleteReferenceNutrient : AuthorizedAccess -> NutrientCode -> Cmd Page.Msg
deleteReferenceNutrient authorizedAccess nutrientCode =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.stats.references.delete nutrientCode)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (GotDeleteReferenceNutrientResponse nutrientCode)
        }


addReferenceNutrient : AuthorizedAccess -> ReferenceNutrientCreation -> Cmd Page.Msg
addReferenceNutrient authorizedAccess referenceNutrientCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.stats.references.create
        { body = encoderReferenceNutrientCreation referenceNutrientCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson GotAddReferenceNutrientResponse decoderReferenceNutrient
        }
