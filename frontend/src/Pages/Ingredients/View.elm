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
import Html exposing (Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, colspan, disabled, id, scope, value)
import Html.Attributes.Extra exposing (stringProperty)
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
import Util.SearchUtil as SearchUtil


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
                    |> Dict.filter (\_ v -> SearchUtil.search searchString v.name)
                    |> Dict.values
                    |> List.sortBy .name
                    |> List.map (viewFoodLine model.foods model.measures model.foodsToAdd model.ingredients)

            anySelection =
                model.foodsToAdd
                    |> Dict.isEmpty
                    |> not

            ( amount, unit ) =
                if anySelection then
                    ( "Amount", "Unit" )

                else
                    ( "", "" )
        in
        div [ id "ingredientEditor" ]
            [ div []
                [ table [ class "info" ]
                    [ tr []
                        [ td [ class "descriptionColumn" ] [ label [] [ text "Recipe" ] ]
                        , td [] [ label [] [ text <| Maybe.Extra.unwrap "" .name <| model.recipeInfo ] ]
                        ]
                    , tr []
                        [ td [ class "descriptionColumn" ] [ label [] [ text "Description" ] ]
                        , td [] [ label [] [ text <| Maybe.withDefault "" <| Maybe.andThen .description <| model.recipeInfo ] ]
                        ]
                    ]
                ]
            , div [ class "elements" ] [ label [] [ text "Ingredients" ] ]
            , div [ class "choices" ]
                [ table []
                    [ colgroup []
                        [ col [] []
                        , col [] []
                        , col [] []
                        , col [ stringProperty "span" "2" ] []
                        ]
                    , thead []
                        [ tr [ class "tableHeader" ]
                            [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                            , th [ scope "col", class "numberLabel" ] [ label [] [ text "Amount" ] ]
                            , th [ scope "col", class "numberLabel" ] [ label [] [ text "Unit" ] ]
                            , th [ colspan 2, scope "colgroup", class "controlsGroup" ] []
                            ]
                        ]
                    , tbody []
                        (viewEditIngredients
                            (model.ingredients
                                |> Dict.values
                                |> List.sortBy (Editing.field .foodId >> Page.ingredientNameOrEmpty model.foods >> String.toLower)
                            )
                        )
                    ]
                ]
            , div [ class "addView" ]
                [ div [ class "addElement" ]
                    [ div [ class "searchArea" ]
                        [ label [] [ text Links.lookingGlass ]
                        , input
                            [ onInput Page.SetFoodsSearchString
                            , value <| model.foodsSearchString
                            , class "searchField"
                            ]
                            []
                        , button
                            [ class "cancelButton"
                            , onClick (Page.SetFoodsSearchString "")
                            , disabled <| String.isEmpty <| model.foodsSearchString
                            ]
                            [ text "Clear" ]
                        ]
                    , table [ class "choiceTable" ]
                        [ colgroup []
                            [ col [] []
                            , col [] []
                            , col [] []
                            , col [ stringProperty "span" "2" ] []
                            ]
                        , thead []
                            [ tr [ class "tableHeader" ]
                                [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                                , th [ scope "col", class "numberLabel" ] [ label [] [ text amount ] ]
                                , th [ scope "col", class "numberLabel" ] [ label [] [ text unit ] ]
                                , th [ colspan 2, scope "colgroup", class "controlsGroup" ] []
                                ]
                            ]
                        , tbody [] (viewFoods model.foodsSearchString)
                        ]
                    ]
                ]
            ]


editOrDeleteIngredientLine : Page.MeasureMap -> Page.FoodMap -> Ingredient -> Html Page.Msg
editOrDeleteIngredientLine measureMap foodMap ingredient =
    tr [ class "editing" ]
        [ td [ class "editable" ] [ label [] [ text <| Page.ingredientNameOrEmpty foodMap <| ingredient.foodId ] ]
        , td [ class "editable", class "numberLabel" ] [ label [] [ text <| String.fromFloat <| ingredient.amountUnit.factor ] ]
        , td [ class "editable", class "numberLabel" ] [ label [] [ text <| Maybe.Extra.unwrap "" .name <| flip Dict.get measureMap <| ingredient.amountUnit.measureId ] ]
        , td [ class "controls" ] [ button [ class "editButton", onClick (Page.EnterEditIngredient ingredient.id) ] [ text "Edit" ] ]
        , td [ class "controls" ] [ button [ class "deleteButton", onClick (Page.DeleteIngredient ingredient.id) ] [ text "Delete" ] ]
        ]


editIngredientLine : Page.MeasureMap -> Page.FoodMap -> Ingredient -> IngredientUpdateClientInput -> Html Page.Msg
editIngredientLine measureMap foodMap ingredient ingredientUpdateClientInput =
    tr [ class "editLine" ]
        [ td [] [ label [] [ text (ingredient.foodId |> Page.ingredientNameOrEmpty foodMap) ] ]
        , td [ class "numberCell" ]
            [ input
                [ value
                    (ingredientUpdateClientInput.amountUnit.factor.value
                        |> String.fromFloat
                    )
                , onInput
                    (flip
                        (ValidatedInput.lift
                            (IngredientUpdateClientInput.lenses.amountUnit
                                |> Compose.lensWithLens AmountUnitClientInput.factor
                            )
                        ).set
                        ingredientUpdateClientInput
                        >> Page.UpdateIngredient
                    )
                , onEnter (Page.SaveIngredientEdit ingredientUpdateClientInput)
                , class "numberLabel"
                ]
                []
            ]
        , td [ class "numberCell" ]
            [ dropdown
                { items = unitDropdown foodMap ingredient.foodId
                , emptyItem =
                    Just <| startingDropdownUnit measureMap ingredient.amountUnit.measureId
                , onChange =
                    onChangeDropdown
                        { amountUnitLens = IngredientUpdateClientInput.lenses.amountUnit
                        , measureIdOf = .amountUnit >> .measureId
                        , mkMsg = Page.UpdateIngredient
                        , input = ingredientUpdateClientInput
                        }
                }
                [ class "numberLabel" ]
                (ingredient.amountUnit.measureId
                    |> flip Dict.get measureMap
                    |> Maybe.map .name
                )
            ]
        , td []
            [ button [ class "confirmButton", onClick (Page.SaveIngredientEdit ingredientUpdateClientInput) ]
                [ text "Save" ]
            ]
        , td []
            [ button [ class "cancelButton", onClick (Page.ExitEditIngredientAt ingredient.id) ]
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
                    [ td [ class "editable", class "numberCell" ] []
                    , td [ class "editable", class "numberCell" ] []
                    , td [ class "controls" ] []
                    , td [ class "controls" ] [ button [ class "selectButton", onClick (Page.SelectFood food) ] [ text "Select" ] ]
                    ]

                Just ingredientToAdd ->
                    let
                        ( confirmName, confirmMsg ) =
                            case DictUtil.firstSuch (\ingredient -> Editing.field .foodId ingredient == ingredientToAdd.foodId) ingredients of
                                Nothing ->
                                    ( "Add", addMsg )

                                Just ingredientOrUpdate ->
                                    let
                                        ingredient =
                                            Editing.field identity ingredientOrUpdate
                                    in
                                    ( "Update"
                                    , ingredient
                                        |> IngredientUpdateClientInput.from
                                        |> IngredientUpdateClientInput.lenses.amountUnit.set ingredientToAdd.amountUnit
                                        |> Page.SaveIngredientEdit
                                    )
                    in
                    [ td [ class "numberCell" ]
                        [ input
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
                            , onEnter confirmMsg
                            , class "numberLabel"
                            ]
                            []
                        ]
                    , td [ class "numberCell" ]
                        [ dropdown
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
                            [ class "numberLabel" ]
                            (ingredientToAdd.amountUnit.measureId |> String.fromInt |> Just)
                        ]
                    , td [ class "controls" ]
                        [ button
                            [ class "confirmButton"
                            , disabled
                                (ingredientToAdd.amountUnit.factor |> ValidatedInput.isValid |> not)
                            , onClick confirmMsg
                            ]
                            [ text confirmName
                            ]
                        ]
                    , td [ class "controls" ]
                        [ button [ class "cancelButton", onClick (Page.DeselectFood food.id) ] [ text "Cancel" ] ]
                    ]
    in
    tr [ class "editing" ]
        (td [ class "editable" ] [ label [] [ text food.name ] ]
            :: process
        )
