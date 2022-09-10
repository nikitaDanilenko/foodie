module Pages.Recipes.Page exposing (..)

import Api.Auxiliary exposing (JWT, RecipeId)
import Api.Types.Recipe exposing (Recipe)
import Api.Types.RecipeUpdate exposing (RecipeUpdate)
import Configuration exposing (Configuration)
import Either exposing (Either)
import Http exposing (Error)
import Monocle.Lens exposing (Lens)
import Util.Editing exposing (Editing)
import Util.LensUtil as LensUtil


type alias Model =
    { flagsWithJWT : FlagsWithJWT
    , recipes : List RecipeOrUpdate
    }


type alias RecipeOrUpdate =
    Either Recipe (Editing Recipe RecipeUpdate)


lenses :
    { jwt : Lens Model JWT
    , recipes : Lens Model (List RecipeOrUpdate)
    }
lenses =
    { jwt = LensUtil.jwtSubLens
    , recipes = Lens .recipes (\b a -> { a | recipes = b })
    }


type alias Flags =
    { configuration : Configuration
    , jwt : Maybe String
    }


type alias FlagsWithJWT =
    { configuration : Configuration
    , jwt : String
    }


type Msg
    = CreateRecipe
    | GotCreateRecipeResponse (Result Error Recipe)
    | UpdateRecipe RecipeUpdate
    | SaveRecipeEdit RecipeId
    | GotSaveRecipeResponse (Result Error Recipe)
    | EnterEditRecipe RecipeId
    | ExitEditRecipeAt RecipeId
    | DeleteRecipe RecipeId
    | GotDeleteRecipeResponse RecipeId (Result Error ())
    | GotFetchRecipesResponse (Result Error (List Recipe))
    | UpdateJWT JWT
