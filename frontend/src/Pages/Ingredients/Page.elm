module Pages.Ingredients.Page exposing (..)

import Api.Auxiliary exposing (ComplexFoodId, ComplexIngredientId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexIngredient exposing (ComplexIngredient)
import Api.Types.Food exposing (Food)
import Api.Types.Ingredient exposing (Ingredient)
import Monocle.Lens exposing (Lens)
import Pages.Ingredients.Complex.Page
import Pages.Ingredients.Plain.Page
import Pages.Ingredients.Recipe.Page
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Page
import Pages.Util.Parent.Page
import Pages.View.Tristate as Tristate exposing (Status(..))


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , recipe : Pages.Ingredients.Recipe.Page.Main
    , ingredientsGroup : Pages.Ingredients.Plain.Page.Main
    , complexIngredientsGroup : Pages.Ingredients.Complex.Page.Main
    , foodsMode : FoodsMode
    }


type alias Initial =
    { jwt : JWT
    , recipe : Pages.Ingredients.Recipe.Page.Initial
    , ingredientsGroup : Pages.Util.Choice.Page.Initial RecipeId IngredientId Ingredient FoodId Food
    , complexIngredientsGroup : Pages.Util.Choice.Page.Initial RecipeId ComplexIngredientId ComplexIngredient ComplexFoodId ComplexFood
    }


initial : AuthorizedAccess -> RecipeId -> Model
initial authorizedAccess recipeId =
    { jwt = authorizedAccess.jwt
    , recipe = Pages.Util.Parent.Page.initialWith authorizedAccess.jwt
    , ingredientsGroup = Pages.Util.Choice.Page.initialWith authorizedAccess.jwt recipeId
    , complexIngredientsGroup = Pages.Util.Choice.Page.initialWith authorizedAccess.jwt recipeId
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    i.recipe
        |> Pages.Util.Parent.Page.initialToMain
        |> Maybe.andThen
            (\recipe ->
                i.ingredientsGroup
                    |> Pages.Util.Choice.Page.initialToMain
                    |> Maybe.andThen
                        (\ingredientsGroup ->
                            i.complexIngredientsGroup
                                |> Pages.Util.Choice.Page.initialToMain
                                |> Maybe.map
                                    (\complexIngredientsGroup ->
                                        { jwt = i.jwt
                                        , recipe = recipe
                                        , ingredientsGroup = ingredientsGroup
                                        , complexIngredientsGroup = complexIngredientsGroup
                                        , foodsMode = Plain
                                        }
                                    )
                        )
            )


type FoodsMode
    = Plain
    | Complex


lenses :
    { initial :
        { ingredientsGroup : Lens Initial (Pages.Util.Choice.Page.Initial RecipeId IngredientId Ingredient FoodId Food)
        , complexIngredientsGroup : Lens Initial (Pages.Util.Choice.Page.Initial RecipeId ComplexIngredientId ComplexIngredient ComplexFoodId ComplexFood)
        , recipe : Lens Initial Pages.Ingredients.Recipe.Page.Initial
        }
    , main :
        { ingredientsGroup : Lens Main Pages.Ingredients.Plain.Page.Main
        , complexIngredientsGroup : Lens Main Pages.Ingredients.Complex.Page.Main
        , recipe : Lens Main Pages.Ingredients.Recipe.Page.Main
        , foodsMode : Lens Main FoodsMode
        }
    }
lenses =
    { initial =
        { ingredientsGroup = Lens .ingredientsGroup (\b a -> { a | ingredientsGroup = b })
        , complexIngredientsGroup = Lens .complexIngredientsGroup (\b a -> { a | complexIngredientsGroup = b })
        , recipe = Lens .recipe (\b a -> { a | recipe = b })
        }
    , main =
        { ingredientsGroup = Lens .ingredientsGroup (\b a -> { a | ingredientsGroup = b })
        , complexIngredientsGroup = Lens .complexIngredientsGroup (\b a -> { a | complexIngredientsGroup = b })
        , recipe = Lens .recipe (\b a -> { a | recipe = b })
        , foodsMode = Lens .foodsMode (\b a -> { a | foodsMode = b })
        }
    }


type alias Msg =
    Tristate.Msg LogicMsg


type LogicMsg
    = UpdateFoods String
    | ChangeFoodsMode FoodsMode
    | IngredientMsg Pages.Ingredients.Plain.Page.LogicMsg
    | ComplexIngredientMsg Pages.Ingredients.Complex.Page.LogicMsg
    | RecipeMsg Pages.Ingredients.Recipe.Page.LogicMsg


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , recipeId : RecipeId
    }
