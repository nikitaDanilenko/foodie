module Pages.Recipes.Requests exposing (createRecipe, deleteRecipe, fetchRecipes, saveRecipe)

import Addresses.Backend
import Api.Auxiliary exposing (JWT, RecipeId)
import Api.Types.Recipe exposing (Recipe, decoderRecipe)
import Api.Types.RecipeCreation exposing (RecipeCreation, encoderRecipeCreation)
import Api.Types.RecipeUpdate exposing (RecipeUpdate, encoderRecipeUpdate)
import Http
import Json.Decode as Decode
import Pages.Recipes.Page as Page
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Util.HttpUtil as HttpUtil


fetchRecipes : FlagsWithJWT -> Cmd Page.Msg
fetchRecipes flags =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.recipes.all
        { body = Http.emptyBody
        , expect = HttpUtil.expectJson Page.GotFetchRecipesResponse (Decode.list decoderRecipe)
        }


createRecipe : FlagsWithJWT -> RecipeCreation -> Cmd Page.Msg
createRecipe flags recipeCreation =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.recipes.create
        { body = encoderRecipeCreation recipeCreation |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotCreateRecipeResponse decoderRecipe
        }


saveRecipe : FlagsWithJWT -> RecipeUpdate -> Cmd Page.Msg
saveRecipe flags recipeUpdate =
    HttpUtil.runPatternWithJwt
        flags
        Addresses.Backend.recipes.update
        { body = encoderRecipeUpdate recipeUpdate |> Http.jsonBody
        , expect = HttpUtil.expectJson Page.GotSaveRecipeResponse decoderRecipe
        }


deleteRecipe : FlagsWithJWT -> RecipeId -> Cmd Page.Msg
deleteRecipe flags recipeId =
    HttpUtil.runPatternWithJwt
        flags
        (Addresses.Backend.recipes.delete recipeId)
        { body = Http.emptyBody
        , expect = HttpUtil.expectWhatever (Page.GotDeleteRecipeResponse recipeId)
        }
