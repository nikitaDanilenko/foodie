module Pages.Recipes.Page exposing (..)

import Api.Auxiliary exposing (JWT, RecipeId)
import Api.Types.Recipe exposing (Recipe)
import Dict exposing (Dict)
import Either exposing (Either)
import Monocle.Lens exposing (Lens)
import Pages.Recipes.Pagination exposing (Pagination)
import Pages.Recipes.RecipeCreationClientInput exposing (RecipeCreationClientInput)
import Pages.Recipes.RecipeUpdateClientInput exposing (RecipeUpdateClientInput)
import Pages.Recipes.Status exposing (Status)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.Editing exposing (Editing)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , recipes : RecipeOrUpdateMap
    , recipeToAdd : Maybe RecipeCreationClientInput
    , initialization : Initialization Status
    , pagination : Pagination
    }


type alias RecipeOrUpdate =
    Either Recipe (Editing Recipe RecipeUpdateClientInput)


type alias RecipeOrUpdateMap =
    Dict RecipeId RecipeOrUpdate


lenses :
    { recipes : Lens Model RecipeOrUpdateMap
    , recipeToAdd : Lens Model (Maybe RecipeCreationClientInput)
    , initialization : Lens Model (Initialization Status)
    , pagination : Lens Model Pagination
    }
lenses =
    { recipes = Lens .recipes (\b a -> { a | recipes = b })
    , recipeToAdd = Lens .recipeToAdd (\b a -> { a | recipeToAdd = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , pagination = Lens .pagination (\b a -> { a | pagination = b })
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type Msg
    = UpdateRecipeCreation (Maybe RecipeCreationClientInput)
    | CreateRecipe
    | GotCreateRecipeResponse (Result Error Recipe)
    | UpdateRecipe RecipeUpdateClientInput
    | SaveRecipeEdit RecipeId
    | GotSaveRecipeResponse (Result Error Recipe)
    | EnterEditRecipe RecipeId
    | ExitEditRecipeAt RecipeId
    | DeleteRecipe RecipeId
    | GotDeleteRecipeResponse RecipeId (Result Error ())
    | GotFetchRecipesResponse (Result Error (List Recipe))
    | SetPagination Pagination
