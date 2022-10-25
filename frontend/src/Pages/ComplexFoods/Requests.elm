module Pages.ComplexFoods.Requests exposing (..)

import Addresses.Backend
import Api.Auxiliary exposing (ComplexFoodId)
import Api.Types.ComplexFood exposing (ComplexFood, decoderComplexFood, encoderComplexFood)
import Api.Types.Recipe exposing (decoderRecipe)
import Http
import Json.Decode as Decode
import Pages.ComplexFoods.Page as Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil as HttpUtil


fetchRecipes : AuthorizedAccess -> Cmd Page.Msg
fetchRecipes authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.recipes.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchRecipesResponse (Decode.list decoderRecipe)
        }


fetchComplexFoods : AuthorizedAccess -> Cmd Page.Msg
fetchComplexFoods authorizedAccess =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.complexFoods.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchComplexFoodsResponse (Decode.list decoderComplexFood)
        }


createComplexFood : AuthorizedAccess -> ComplexFood -> Cmd Page.Msg
createComplexFood authorizedAccess complexFood =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.complexFoods.create
        { body = encoderComplexFood complexFood |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotCreateComplexFoodResponse decoderComplexFood
        }


updateComplexFood : AuthorizedAccess -> ComplexFood -> Cmd Page.Msg
updateComplexFood authorizedAccess complexFood =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.complexFoods.update
        { body = encoderComplexFood complexFood |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotSaveComplexFoodResponse decoderComplexFood
        }


deleteComplexFood : AuthorizedAccess -> ComplexFoodId -> Cmd Page.Msg
deleteComplexFood authorizedAccess complexFoodId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.complexFoods.delete complexFoodId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (Page.GotDeleteComplexFoodResponse complexFoodId)
        }
