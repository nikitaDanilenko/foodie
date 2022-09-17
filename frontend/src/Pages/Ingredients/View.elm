module Pages.Ingredients.View exposing (view)

import Api.Auxiliary exposing (FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.AmountUnit exposing (AmountUnit)
import Api.Types.Food exposing (Food)
import Api.Types.Ingredient exposing (Ingredient)
import Api.Types.Measure exposing (Measure)
import Basics.Extra exposing (flip)
import Dict exposing (Dict)
import Dropdown exposing (Item, dropdown)
import Either exposing (Either(..))
import Html exposing (Html, button, div, input, label, td, text, thead, tr)
import Html.Attributes exposing (class, disabled, id, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Ingredients.AmountUnitClientInput as AmountUnitClientInput
import Pages.Ingredients.IngredientCreationClientInput as IngredientCreationClientInput exposing (IngredientCreationClientInput)
import Pages.Ingredients.IngredientUpdateClientInput as IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.Ingredients.Page as Page
import Pages.Ingredients.RecipeInfo exposing (RecipeInfo)
import Pages.Ingredients.Status as Status
import Pages.Util.DictUtil as DictUtil
import Pages.Util.Links as Links
import Pages.Util.ValidatedInput as ValidatedInput
import Pages.Util.ViewUtil as ViewUtil
import Util.Editing as Editing


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = .initialization
        , flagsWithJWT = .flagsWithJWT
        }
        model
    <|
        let
            viewEditIngredients =
                List.map
                    (Either.unpack
                        (editOrDeleteIngredientLine model.measures model.foods)
                        (\e -> e.update |> editIngredientLine model.measures model.foods e.original)
                    )

            viewFoods searchString =
                model.foods
                    |> Dict.filter (\_ v -> String.contains (String.toLower searchString) (String.toLower v.name))
                    |> Dict.values
                    |> List.sortBy .name
                    |> List.map (viewFoodLine model.foods model.measures model.foodsToAdd model.ingredients)
        in
        div [ id "editor" ]
            [ div [ id "recipeInfo" ]
                [ label [] [ text "Name" ]
                , label [] [ text <| Maybe.Extra.unwrap "" .name <| model.recipeInfo ]
                , label [] [ text "Description" ]
                , label [] [ text <| Maybe.withDefault "" <| Maybe.andThen .description <| model.recipeInfo ]
                ]
            , div [ id "ingredientsView" ]
                (thead []
                    [ tr []
                        [ td [] [ label [] [ text "Name" ] ]
                        , td [] [ label [] [ text "Amount" ] ]
                        , td [] [ label [] [ text "Unit" ] ]
                        ]
                    ]
                    :: viewEditIngredients
                        (model.ingredients
                            |> Dict.values
                            |> List.sortBy (Editing.field .foodId >> Page.ingredientNameOrEmpty model.foods >> String.toLower)
                        )
                )
            , div [ id "addIngredientView" ]
                (div [ id "addIngredient" ]
                    [ div [ id "searchField" ]
                        [ label [] [ text Links.lookingGlass ]
                        , input [ onInput Page.SetFoodsSearchString ] []
                        ]
                    ]
                    :: thead []
                        [ tr []
                            [ td [] [ label [] [ text "Name" ] ]
                            ]
                        ]
                    :: viewFoods model.foodsSearchString
                )
            ]


editOrDeleteIngredientLine : Page.MeasureMap -> Page.FoodMap -> Ingredient -> Html Page.Msg
editOrDeleteIngredientLine measureMap foodMap ingredient =
    tr [ id "editingIngredient" ]
        [ td [] [ label [] [ text (ingredient.foodId |> Page.ingredientNameOrEmpty foodMap) ] ]
        , td [] [ label [] [ text (ingredient.amountUnit.factor |> String.fromFloat) ] ]
        , td [] [ label [] [ text (ingredient.amountUnit.measureId |> flip Dict.get measureMap |> Maybe.Extra.unwrap "" .name) ] ]
        , td [] [ button [ class "button", onClick (Page.EnterEditIngredient ingredient.id) ] [ text "Edit" ] ]
        , td [] [ button [ class "button", onClick (Page.DeleteIngredient ingredient.id) ] [ text "Delete" ] ]
        ]


editIngredientLine : Page.MeasureMap -> Page.FoodMap -> Ingredient -> IngredientUpdateClientInput -> Html Page.Msg
editIngredientLine measureMap foodMap ingredient ingredientUpdateClientInput =
    tr [ id "ingredientLine" ]
        [ td [] [ label [] [ text (ingredient.foodId |> Page.ingredientNameOrEmpty foodMap) ] ]
        , td []
            [ input
                [ value
                    (ingredientUpdateClientInput.amountUnit.factor.value
                        |> String.fromFloat
                    )
                , onInput
                    (flip
                        (ValidatedInput.lift
                            (IngredientUpdateClientInput.amountUnit
                                |> Compose.lensWithLens AmountUnitClientInput.factor
                            )
                        ).set
                        ingredientUpdateClientInput
                        >> Page.UpdateIngredient
                    )
                , onEnter (Page.SaveIngredientEdit ingredient.id)
                ]
                []
            ]
        , td []
            [ dropdown
                { items = unitDropdown foodMap ingredient.foodId
                , emptyItem =
                    Just <| startingDropdownUnit measureMap ingredient.amountUnit.measureId
                , onChange =
                    onChangeDropdown
                        { amountUnitLens = IngredientUpdateClientInput.amountUnit
                        , measureIdOf = .amountUnit >> .measureId
                        , mkMsg = Page.UpdateIngredient
                        , input = ingredientUpdateClientInput
                        }
                }
                []
                (ingredient.amountUnit.measureId
                    |> flip Dict.get measureMap
                    |> Maybe.map .name
                )
            ]
        , td []
            [ button [ class "button", onClick (Page.SaveIngredientEdit ingredient.id) ]
                [ text "Save" ]
            ]
        , td []
            [ button [ class "button", onClick (Page.ExitEditIngredientAt ingredient.id) ]
                [ text "Cancel" ]
            ]
        ]


unitDropdown : Page.FoodMap -> FoodId -> List Dropdown.Item
unitDropdown fm fId =
    fm
        |> Dict.get fId
        |> Maybe.Extra.unwrap [] .measures
        |> List.map (\m -> { value = String.fromInt m.id, text = m.name, enabled = True })


startingDropdownUnit : Page.MeasureMap -> MeasureId -> Dropdown.Item
startingDropdownUnit mm mId =
    { value = String.fromInt mId
    , text =
        mm
            |> Dict.get mId
            |> Maybe.Extra.unwrap "" .name
    , enabled = True
    }


onChangeDropdown :
    { amountUnitLens : Lens input AmountUnitClientInput.AmountUnitClientInput
    , measureIdOf : input -> MeasureId
    , input : input
    , mkMsg : input -> Page.Msg
    }
    -> Maybe String
    -> Page.Msg
onChangeDropdown ps =
    Maybe.andThen String.toInt
        >> Maybe.withDefault (ps.measureIdOf ps.input)
        >> flip (ps.amountUnitLens |> Compose.lensWithLens AmountUnitClientInput.measureId).set ps.input
        >> ps.mkMsg


viewFoodLine : Page.FoodMap -> Page.MeasureMap -> Page.AddFoodsMap -> Page.IngredientOrUpdateMap -> Food -> Html Page.Msg
viewFoodLine foodMap measureMap ingredientsToAdd ingredients food =
    let
        addMsg =
            Page.AddFood food.id

        process =
            case Dict.get food.id ingredientsToAdd of
                Nothing ->
                    [ td [] [ button [ class "button", onClick (Page.SelectFood food) ] [ text "Select" ] ] ]

                Just ingredientToAdd ->
                    [ td []
                        [ label [] [ text "Amount" ]
                        , input
                            [ value ingredientToAdd.amountUnit.factor.text
                            , onInput
                                (flip
                                    (ValidatedInput.lift
                                        (IngredientCreationClientInput.amountUnit
                                            |> Compose.lensWithLens AmountUnitClientInput.factor
                                        )
                                    ).set
                                    ingredientToAdd
                                    >> Page.UpdateAddFood
                                )
                            , onEnter addMsg
                            ]
                            []
                        ]
                    , td []
                        [ label [] [ text "Unit" ]
                        , dropdown
                            { items = unitDropdown foodMap food.id
                            , emptyItem =
                                Just <| startingDropdownUnit measureMap ingredientToAdd.amountUnit.measureId
                            , onChange =
                                onChangeDropdown
                                    { amountUnitLens = IngredientCreationClientInput.amountUnit
                                    , measureIdOf = .amountUnit >> .measureId
                                    , mkMsg = Page.UpdateAddFood
                                    , input = ingredientToAdd
                                    }
                            }
                            []
                            (ingredientToAdd.amountUnit.measureId |> String.fromInt |> Just)
                        ]
                    , td []
                        [ button
                            [ class "button"
                            , disabled
                                (ingredientToAdd.amountUnit.factor |> ValidatedInput.isValid |> not)
                            , onClick addMsg
                            ]
                            [ text
                                (if DictUtil.existsValue (\i -> Editing.field .foodId i == ingredientToAdd.foodId) ingredients then
                                    "Update"

                                 else
                                    "Add"
                                )
                            ]
                        ]
                    , td [] [ button [ class "button", onClick (Page.DeselectFood food.id) ] [ text "Cancel" ] ]
                    ]
    in
    tr [ id "addingFoodLine" ]
        (td [] [ label [] [ text food.name ] ]
            :: process
        )
