module Pages.Meals.Page exposing (..)

import Api.Auxiliary exposing (JWT, MealId, ProfileId)
import Api.Types.Meal exposing (Meal)
import Pages.Meals.MealCreationClientInput exposing (MealCreationClientInput)
import Pages.Meals.MealUpdateClientInput exposing (MealUpdateClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.ParentEditor.Page
import Pages.View.Tristate as Tristate


type alias Model =
    { parentEditor : Tristate.Model Main Initial
    , profileId : ProfileId
    }


type alias Main =
    Pages.Util.ParentEditor.Page.Main MealId Meal MealCreationClientInput MealUpdateClientInput


type alias Initial =
    Pages.Util.ParentEditor.Page.Initial MealId Meal MealUpdateClientInput


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , profileId : ProfileId
    }


type alias Msg =
    Tristate.Msg LogicMsg


type alias LogicMsg =
    Pages.Util.ParentEditor.Page.LogicMsg MealId Meal MealCreationClientInput MealUpdateClientInput
