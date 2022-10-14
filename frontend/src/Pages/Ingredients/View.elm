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
import Html.Attributes exposing (colspan, disabled, scope, value)
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
import Pages.Ingredients.Pagination as Pagination exposing (Pagination)
import Pages.Ingredients.RecipeInfo exposing (RecipeInfo)
import Pages.Ingredients.Status as Status
import Pages.Util.DictUtil as DictUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput
import Pages.Util.ViewUtil as ViewUtil
import Paginate exposing (PaginatedList)
import Util.Editing as Editing
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = .initialization
        , configuration = .flagsWithJWT >> .configuration
        , jwt = .flagsWithJWT >> .jwt >> Just
        , currentPage = Nothing
        , showNavigation = True
        }
        model
    <|
        let
            viewEditIngredient =
                Either.unpack
                    (editOrDeleteIngredientLine model.measures model.foods)
                    (\e -> e.update |> editIngredientLine model.measures model.foods e.original)

            viewEditIngredients =
                model.ingredients
                    |> Dict.values
                    |> List.sortBy (Editing.field .foodId >> Page.ingredientNameOrEmpty model.foods >> String.toLower)
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.pagination |> Compose.lensWithLens Pagination.lenses.ingredients
                        }
                        model

            viewFoods =
                model.foods
                    |> Dict.filter (\_ v -> SearchUtil.search model.foodsSearchString v.name)
                    |> Dict.values
                    |> List.sortBy .name
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.pagination |> Compose.lensWithLens Pagination.lenses.foods
                        }
                        model

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
        div [ Style.ids.ingredientEditor ]
            [ div []
                [ table [ Style.classes.info ]
                    [ tr []
                        [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Recipe" ] ]
                        , td [] [ label [] [ text <| Maybe.Extra.unwrap "" .name <| model.recipeInfo ] ]
                        ]
                    , tr []
                        [ td [ Style.classes.descriptionColumn ] [ label [] [ text "Description" ] ]
                        , td [] [ label [] [ text <| Maybe.withDefault "" <| Maybe.andThen .description <| model.recipeInfo ] ]
                        ]
                    ]
                ]
            , div [ Style.classes.elements ] [ label [] [ text "Ingredients" ] ]
            , div [ Style.classes.choices ]
                [ table []
                    [ colgroup []
                        [ col [] []
                        , col [] []
                        , col [] []
                        , col [ stringProperty "span" "2" ] []
                        ]
                    , thead []
                        [ tr [ Style.classes.tableHeader ]
                            [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                            , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text "Amount" ] ]
                            , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text "Unit" ] ]
                            , th [ colspan 2, scope "colgroup", Style.classes.controlsGroup ] []
                            ]
                        ]
                    , tbody []
                        (viewEditIngredients
                            |> Paginate.page
                            |> List.map viewEditIngredient
                        )
                    ]
                , div [ Style.classes.pagination ]
                    [ ViewUtil.pagerButtons
                        { msg =
                            PaginationSettings.updateCurrentPage
                                { pagination = Page.lenses.pagination
                                , items = Pagination.lenses.ingredients
                                }
                                model
                                >> Page.SetPagination
                        , elements = viewEditIngredients
                        }
                    ]
                ]
            , div [ Style.classes.addView ]
                [ div [ Style.classes.addElement ]
                    [ HtmlUtil.searchAreaWith
                        { msg = Page.SetFoodsSearchString
                        , searchString = model.foodsSearchString
                        }
                    , table [ Style.classes.choiceTable ]
                        [ colgroup []
                            [ col [] []
                            , col [] []
                            , col [] []
                            , col [ stringProperty "span" "2" ] []
                            ]
                        , thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                                , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text amount ] ]
                                , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text unit ] ]
                                , th [ colspan 2, scope "colgroup", Style.classes.controlsGroup ] []
                                ]
                            ]
                        , tbody []
                            (viewFoods
                                |> Paginate.page
                                |> List.map (viewFoodLine model.foods model.measures model.foodsToAdd model.ingredients)
                            )
                        ]
                    , div [ Style.classes.pagination ]
                        [ ViewUtil.pagerButtons
                            { msg =
                                PaginationSettings.updateCurrentPage
                                    { pagination = Page.lenses.pagination
                                    , items = Pagination.lenses.foods
                                    }
                                    model
                                    >> Page.SetPagination
                            , elements = viewFoods
                            }
                        ]
                    ]
                ]
            ]


editOrDeleteIngredientLine : Page.MeasureMap -> Page.FoodMap -> Ingredient -> Html Page.Msg
editOrDeleteIngredientLine measureMap foodMap ingredient =
    let
        editMsg =
            Page.EnterEditIngredient ingredient.id
    in
    tr [ Style.classes.editing ]
        [ td [ Style.classes.editable, onClick editMsg ] [ label [] [ text <| Page.ingredientNameOrEmpty foodMap <| ingredient.foodId ] ]
        , td [ Style.classes.editable, Style.classes.numberLabel, onClick editMsg ] [ label [] [ text <| String.fromFloat <| ingredient.amountUnit.factor ] ]
        , td [ Style.classes.editable, Style.classes.numberLabel, onClick editMsg ] [ label [] [ text <| Maybe.Extra.unwrap "" .name <| flip Dict.get measureMap <| ingredient.amountUnit.measureId ] ]
        , td [ Style.classes.controls ] [ button [ Style.classes.button.edit, onClick editMsg ] [ text "Edit" ] ]
        , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.DeleteIngredient ingredient.id) ] [ text "Delete" ] ]
        ]


editIngredientLine : Page.MeasureMap -> Page.FoodMap -> Ingredient -> IngredientUpdateClientInput -> Html Page.Msg
editIngredientLine measureMap foodMap ingredient ingredientUpdateClientInput =
    let
        saveMsg =
            Page.SaveIngredientEdit ingredientUpdateClientInput

        cancelMsg =
            Page.ExitEditIngredientAt ingredient.id
    in
    tr [ Style.classes.editLine ]
        [ td [] [ label [] [ text <| Page.ingredientNameOrEmpty foodMap <| ingredient.foodId ] ]
        , td [ Style.classes.numberCell ]
            [ input
                [ value
                    ingredientUpdateClientInput.amountUnit.factor.text
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
                , onEnter saveMsg
                , HtmlUtil.onEscape cancelMsg
                , Style.classes.numberLabel
                ]
                []
            ]
        , td [ Style.classes.numberCell ]
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
                [ Style.classes.numberLabel, HtmlUtil.onEscape cancelMsg ]
                (ingredient.amountUnit.measureId
                    |> flip Dict.get measureMap
                    |> Maybe.map .name
                )
            ]
        , td []
            [ button [ Style.classes.button.confirm, onClick saveMsg ]
                [ text "Save" ]
            ]
        , td []
            [ button [ Style.classes.button.cancel, onClick cancelMsg ]
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

        selectMsg =
            Page.SelectFood food

        cancelMsg =
            Page.DeselectFood food.id

        maybeIngredientToAdd =
            Dict.get food.id ingredientsToAdd

        rowClickAction =
            if Maybe.Extra.isJust maybeIngredientToAdd then
                []

            else
                [ onClick selectMsg ]

        process =
            case maybeIngredientToAdd of
                Nothing ->
                    [ td [ Style.classes.editable, Style.classes.numberCell ] []
                    , td [ Style.classes.editable, Style.classes.numberCell ] []
                    , td [ Style.classes.controls ] []
                    , td [ Style.classes.controls ] [ button [ Style.classes.button.select, onClick selectMsg ] [ text "Select" ] ]
                    ]

                Just ingredientToAdd ->
                    let
                        validInput =
                            ingredientToAdd.amountUnit.factor |> ValidatedInput.isValid

                        ( confirmName, confirmMsg ) =
                            case DictUtil.firstSuch (\ingredient -> Editing.field .foodId ingredient == ingredientToAdd.foodId) ingredients of
                                Nothing ->
                                    ( "Add", addMsg )

                                Just ingredientOrUpdate ->
                                    ( "Update"
                                    , ingredientOrUpdate
                                        |> Editing.field identity
                                        |> IngredientUpdateClientInput.from
                                        |> IngredientUpdateClientInput.lenses.amountUnit.set ingredientToAdd.amountUnit
                                        |> Page.SaveIngredientEdit
                                    )
                    in
                    [ td [ Style.classes.numberCell ]
                        [ input
                            ([ value ingredientToAdd.amountUnit.factor.text
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
                             , Style.classes.numberLabel
                             , HtmlUtil.onEscape cancelMsg
                             ]
                                ++ (if validInput then
                                        [ onEnter confirmMsg ]

                                    else
                                        []
                                   )
                            )
                            []
                        ]
                    , td [ Style.classes.numberCell ]
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
                            [ Style.classes.numberLabel
                            , HtmlUtil.onEscape cancelMsg
                            ]
                            (ingredientToAdd.amountUnit.measureId |> String.fromInt |> Just)
                        ]
                    , td [ Style.classes.controls ]
                        [ button
                            [ Style.classes.button.confirm
                            , disabled <| not <| validInput
                            , onClick confirmMsg
                            ]
                            [ text confirmName
                            ]
                        ]
                    , td [ Style.classes.controls ]
                        [ button [ Style.classes.button.cancel, onClick cancelMsg ] [ text "Cancel" ] ]
                    ]
    in
    tr ([ Style.classes.editing ] ++ rowClickAction)
        (td [ Style.classes.editable ] [ label [] [ text food.name ] ]
            :: process
        )
