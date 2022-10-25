module Pages.ComplexFoods.Page exposing (..)

import Api.Auxiliary exposing (ComplexFoodId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.Recipe exposing (Recipe)
import Dict exposing (Dict)
import Either exposing (Either)
import Http exposing (Error)
import Monocle.Lens exposing (Lens)
import Pages.ComplexFoods.ComplexFoodClientInput exposing (ComplexFoodClientInput)
import Pages.ComplexFoods.Pagination exposing (Pagination)
import Pages.ComplexFoods.Status exposing (Status)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.Editing exposing (Editing)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , recipes : List Recipe
    , complexFoods : ComplexFoodOrUpdateMap
    , complexFoodToAdd : Maybe ComplexFoodClientInput
    , recipesSearchString: String
    , initialization : Initialization Status
    , pagination : Pagination
    }


type alias ComplexFoodOrUpdate =
    Either ComplexFood (Editing ComplexFood ComplexFoodClientInput)


type alias ComplexFoodOrUpdateMap =
    Dict ComplexFoodId ComplexFoodOrUpdate


lenses :
    { recipes : Lens Model (List Recipe)
    , complexFoods : Lens Model ComplexFoodOrUpdateMap
    , complexFoodToAdd : Lens Model (Maybe ComplexFoodClientInput)
    , recipesSearchString : Lens Model String
    , initialization : Lens Model (Initialization Status)
    , pagination : Lens Model Pagination
    }
lenses =
    { recipes = Lens .recipes (\b a -> { a | recipes = b })
    , complexFoods = Lens .complexFoods (\b a -> { a | complexFoods = b })
    , complexFoodToAdd = Lens .complexFoodToAdd (\b a -> { a | complexFoodToAdd = b })
    , recipesSearchString = Lens .recipesSearchString (\b a -> { a | recipesSearchString = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , pagination = Lens .pagination (\b a -> { a | pagination = b })
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type Msg
    = UpdateComplexFoodCreation (Maybe ComplexFoodClientInput)
    | AddComplexFood RecipeId
    | GotAddComplexFoodResponse (Result Error ComplexFood)
    | UpdateComplexFood ComplexFoodClientInput
    | SaveComplexFoodEdit ComplexFoodId
    | GotSaveComplexFoodResponse (Result Error ComplexFood)
    | EnterEditComplexFood ComplexFoodId
    | ExitEditComplexFood ComplexFoodId
    | DeleteComplexFood ComplexFoodId
    | GotDeleteComplexFoodResponse ComplexFoodId (Result Error ())
    | GotFetchRecipesResponse (Result Error (List Recipe))
    | GotFetchComplexFoodsResponse (Result Error (List ComplexFood))
    | SelectRecipe Recipe
    | DeselectRecipe RecipeId
    | SetRecipesSearchString String
    | SetPagination Pagination
