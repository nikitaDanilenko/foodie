module Pages.Recipes.Requests exposing (createRecipe, deleteRecipe, fetchRecipes, saveRecipe)

import Addresses.Backend
import Api.Auxiliary exposing (JWT, RecipeId)
import Api.Types.Recipe exposing (Recipe, decoderRecipe)
import Api.Types.RecipeCreation exposing (RecipeCreation, encoderRecipeCreation)
import Api.Types.RecipeUpdate exposing (RecipeUpdate, encoderRecipeUpdate)
import Http
import Json.Decode as Decode
import Pages.Recipes.Page as Page
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


createRecipe : AuthorizedAccess -> RecipeCreation -> Cmd Page.Msg
createRecipe authorizedAccess recipeCreation =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.recipes.create
        { body = encoderRecipeCreation recipeCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotCreateRecipeResponse decoderRecipe
        }


saveRecipe : AuthorizedAccess -> RecipeUpdate -> Cmd Page.Msg
saveRecipe authorizedAccess recipeUpdate =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        Addresses.Backend.recipes.update
        { body = encoderRecipeUpdate recipeUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotSaveRecipeResponse decoderRecipe
        }


deleteRecipe : AuthorizedAccess -> RecipeId -> Cmd Page.Msg
deleteRecipe authorizedAccess recipeId =
    HttpUtil.runPatternWithJwt
        authorizedAccess
        (Addresses.Backend.recipes.delete recipeId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (Page.GotDeleteRecipeResponse recipeId)
        }
