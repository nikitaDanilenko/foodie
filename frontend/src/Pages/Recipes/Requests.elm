module Pages.Recipes.Requests exposing (fetchRecipes, createRecipe, saveRecipe, deleteRecipe)

import Api.Auxiliary exposing (JWT, RecipeId)
import Api.Types.Recipe exposing (Recipe, decoderRecipe)
import Api.Types.RecipeCreation exposing (RecipeCreation, encoderRecipeCreation)
import Api.Types.RecipeUpdate exposing (RecipeUpdate, encoderRecipeUpdate)
import Configuration exposing (Configuration)
import Json.Decode as Decode
import Pages.Recipes.Page as Page
import Url.Builder
import Util.HttpUtil as HttpUtil


fetchRecipes : Page.FlagsWithJWT -> Cmd Page.Msg
fetchRecipes flags =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "recipe", "all" ] []
        , expect = HttpUtil.expectJson Page.GotFetchRecipesResponse (Decode.list decoderRecipe)
        }


createRecipe : Page.FlagsWithJWT -> Cmd Page.Msg
createRecipe flags =
    let
        defaultRecipeCreation =
            { name = ""
            , description = Nothing
            }
    in
    HttpUtil.postJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "recipe", "create" ] []
        , body = encoderRecipeCreation defaultRecipeCreation
        , expect = HttpUtil.expectJson Page.GotCreateRecipeResponse decoderRecipe
        }


saveRecipe : Page.FlagsWithJWT -> RecipeUpdate -> Cmd Page.Msg
saveRecipe flags recipeUpdate =
    HttpUtil.patchJsonWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "recipe", "update" ] []
        , body = encoderRecipeUpdate recipeUpdate
        , expect = HttpUtil.expectJson Page.GotSaveRecipeResponse decoderRecipe
        }


deleteRecipe : Page.FlagsWithJWT -> RecipeId -> Cmd Page.Msg
deleteRecipe flags recipeId =
    HttpUtil.deleteWithJWT flags.jwt
        { url = Url.Builder.relative [ flags.configuration.backendURL, "recipe", "delete", recipeId ] []
        , expect = HttpUtil.expectWhatever (Page.GotDeleteRecipeResponse recipeId)
        }
