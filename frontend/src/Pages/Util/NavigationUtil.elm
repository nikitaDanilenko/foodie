module Pages.Util.NavigationUtil exposing (..)

import Addresses.Frontend
import Api.Auxiliary exposing (MealId, ProfileId, RecipeId)
import Html exposing (Html, text)
import Pages.Util.Links as Links
import Pages.Util.Style as Style


recipeEditorLinkButton : RecipeId -> Html msg
recipeEditorLinkButton recipeId =
    Links.linkButton
        { url =
            recipeId
                |> Addresses.Frontend.ingredientEditor.address
                |> Links.frontendPage
        , attributes = [ Style.classes.button.editor ]
        , children = [ text "Recipe" ]
        }


recipeNutrientsLinkButton : RecipeId -> Html msg
recipeNutrientsLinkButton recipeId =
    nutrientButtonWith
        { address =
            recipeId
                |> Addresses.Frontend.statisticsRecipeSelect.address
                |> Links.frontendPage
        }


mealEditorLinkButton : ProfileId -> MealId -> Html msg
mealEditorLinkButton profileId mealId =
    Links.linkButton
        { url =
            ( profileId, mealId )
                |> Addresses.Frontend.mealEntryEditor.address
                |> Links.frontendPage
        , attributes = [ Style.classes.button.editor ]
        , children = [ text "Meal" ]
        }


mealNutrientsLinkButton : ProfileId -> MealId -> Html msg
mealNutrientsLinkButton profileId mealId =
    nutrientButtonWith
        { address =
            ( profileId, mealId )
                |> Addresses.Frontend.statisticsMealSelect.address
                |> Links.frontendPage
        }


complexFoodNutrientLinkButton : RecipeId -> Html msg
complexFoodNutrientLinkButton recipeId =
    nutrientButtonWith
        { address =
            recipeId
                |> Addresses.Frontend.statisticsComplexFoodSelect.address
                |> Links.frontendPage
        }


nutrientButtonWith : { address : String } -> Html msg
nutrientButtonWith ps =
    Links.linkButton
        { url = ps.address
        , attributes = [ Style.classes.button.nutrients ]
        , children = [ text "Nutrients" ]
        }
