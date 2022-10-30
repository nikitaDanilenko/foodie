module Pages.Ingredients.View exposing (view)

import Api.Auxiliary exposing (ComplexFoodId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.AmountUnit exposing (AmountUnit)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexFoodUnit as ComplexFoodUnit
import Api.Types.ComplexIngredient exposing (ComplexIngredient)
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
import Pages.Ingredients.ComplexIngredientClientInput as ComplexIngredientClientInput exposing (ComplexIngredientClientInput)
import Pages.Ingredients.FoodGroup as FoodGroup exposing (FoodGroup, IngredientOrUpdate)
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
        , configuration = .authorizedAccess >> .configuration
        , jwt = .authorizedAccess >> .jwt >> Just
        , currentPage = Nothing
        , showNavigation = True
        }
        model
    <|
        let
            viewEditIngredient =
                Either.unpack
                    (editOrDeleteIngredientLine model.measures model.ingredientsGroup.foods)
                    (\e -> e.update |> editIngredientLine model.measures model.ingredientsGroup.foods e.original)

            viewEditComplexIngredient =
                Either.unpack
                    (editOrDeleteComplexIngredientLine model.allRecipes model.complexIngredientsGroup.foods)
                    (\e -> e.update |> editComplexIngredientLine model.allRecipes model.complexIngredientsGroup.foods e.original)

            viewEditIngredientsWith :
                (IngredientOrUpdate ingredient update -> Bool)
                -> Lens Page.Model (FoodGroup comparableIngredientId ingredient update comparableFoodId food creation)
                -> (ingredient -> comparableFoodId)
                -> Dict comparableFoodId { a | name : String }
                -> PaginatedList (IngredientOrUpdate ingredient update)
            viewEditIngredientsWith searchFilter groupLens idOf nameMap =
                model
                    |> groupLens.get
                    |> .ingredients
                    |> Dict.filter (\_ v -> searchFilter v)
                    |> Dict.values
                    |> List.sortBy (Editing.field idOf >> DictUtil.nameOrEmpty nameMap >> String.toLower)
                    |> ViewUtil.paginate
                        { pagination =
                            groupLens
                                |> Compose.lensWithLens FoodGroup.lenses.pagination
                                |> Compose.lensWithLens Pagination.lenses.ingredients
                        }
                        model

            viewEditIngredients =
                viewEditIngredientsWith
                    (Editing.field (.foodId >> DictUtil.nameOrEmpty model.ingredientsGroup.foods)
                        >> SearchUtil.search model.ingredientsSearchString
                    )
                    Page.lenses.ingredientsGroup
                    .foodId
                    model.ingredientsGroup.foods

            viewEditComplexIngredients =
                viewEditIngredientsWith
                    (Editing.field .complexFoodId
                        >> (\id -> complexFoodInfo id model.allRecipes model.complexIngredientsGroup.foods)
                        >> .name
                        >> SearchUtil.search model.complexIngredientsSearchString
                    )
                    Page.lenses.complexIngredientsGroup
                    .complexFoodId
                    model.allRecipes
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
                [ HtmlUtil.searchAreaWith
                    { msg = Page.SetIngredientsSearchString
                    , searchString = model.ingredientsSearchString
                    }
                , table []
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
                                { pagination = Page.lenses.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.pagination
                                , items = Pagination.lenses.ingredients
                                }
                                model
                                >> Page.SetIngredientsPagination
                        , elements = viewEditIngredients
                        }
                    ]
                ]
            , div [ Style.classes.elements ] [ label [] [ text "Complex ingredients" ] ]
            , div [ Style.classes.choices ]
                [ HtmlUtil.searchAreaWith
                    { msg = Page.SetComplexIngredientsSearchString
                    , searchString = model.complexIngredientsSearchString
                    }
                , table []
                    [ colgroup []
                        [ col [] []
                        , col [] []
                        , col [] []
                        , col [ stringProperty "span" "2" ] []
                        ]
                    , thead []
                        [ tr [ Style.classes.tableHeader ]
                            [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                            , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text "Factor" ] ]
                            , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text "Amount" ] ]
                            , th [ colspan 2, scope "colgroup", Style.classes.controlsGroup ] []
                            ]
                        ]
                    , tbody []
                        (viewEditComplexIngredients
                            |> Paginate.page
                            |> List.map viewEditComplexIngredient
                        )
                    ]
                , div [ Style.classes.pagination ]
                    [ ViewUtil.pagerButtons
                        { msg =
                            PaginationSettings.updateCurrentPage
                                { pagination = Page.lenses.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.pagination
                                , items = Pagination.lenses.ingredients
                                }
                                model
                                >> Page.SetComplexIngredientsPagination
                        , elements = viewEditComplexIngredients
                        }
                    ]
                ]
            , div []
                [ button
                    [ disabled <| model.foodsMode == Page.Plain
                    , onClick <| Page.ChangeFoodsMode Page.Plain
                    , Style.classes.button.alternative
                    ]
                    [ text "Ingredients" ]
                , button
                    [ disabled <| model.foodsMode == Page.Complex
                    , onClick <| Page.ChangeFoodsMode Page.Complex
                    , Style.classes.button.alternative
                    ]
                    [ text "Complex ingredients" ]
                ]
            , case model.foodsMode of
                Page.Plain ->
                    viewPlain model

                Page.Complex ->
                    viewComplex model
            ]


viewPlain : Page.Model -> Html Page.Msg
viewPlain model =
    let
        viewFoods =
            model.ingredientsGroup.foods
                |> Dict.filter (\_ v -> SearchUtil.search model.ingredientsGroup.foodsSearchString v.name)
                |> Dict.values
                |> List.sortBy .name
                |> ViewUtil.paginate
                    { pagination =
                        Page.lenses.ingredientsGroup
                            |> Compose.lensWithLens FoodGroup.lenses.pagination
                            |> Compose.lensWithLens Pagination.lenses.foods
                    }
                    model

        ( amount, unit ) =
            if anySelection Page.lenses.ingredientsGroup model then
                ( "Amount", "Unit" )

            else
                ( "", "" )
    in
    div [ Style.classes.addView ]
        [ div [ Style.classes.addElement ]
            [ HtmlUtil.searchAreaWith
                { msg = Page.SetFoodsSearchString
                , searchString = model.ingredientsGroup.foodsSearchString
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
                        |> List.map (viewFoodLine model.ingredientsGroup.foods model.ingredientsGroup.foodsToAdd model.ingredientsGroup.ingredients)
                    )
                ]
            , div [ Style.classes.pagination ]
                [ ViewUtil.pagerButtons
                    { msg =
                        PaginationSettings.updateCurrentPage
                            { pagination = Page.lenses.ingredientsGroup |> Compose.lensWithLens FoodGroup.lenses.pagination
                            , items = Pagination.lenses.foods
                            }
                            model
                            >> Page.SetComplexIngredientsPagination
                    , elements = viewFoods
                    }
                ]
            ]
        ]


viewComplex : Page.Model -> Html Page.Msg
viewComplex model =
    let
        viewComplexFoods =
            model.complexIngredientsGroup.foods
                |> Dict.filter (\k _ -> SearchUtil.search model.complexIngredientsGroup.foodsSearchString (DictUtil.nameOrEmpty model.allRecipes k))
                |> Dict.toList
                |> List.sortBy (Tuple.first >> DictUtil.nameOrEmpty model.allRecipes)
                |> List.map Tuple.second
                |> ViewUtil.paginate
                    { pagination =
                        Page.lenses.complexIngredientsGroup
                            |> Compose.lensWithLens FoodGroup.lenses.pagination
                            |> Compose.lensWithLens Pagination.lenses.foods
                    }
                    model

        ( amount, unit ) =
            if anySelection Page.lenses.complexIngredientsGroup model then
                ( "Factor", "Amount" )

            else
                ( "", "" )
    in
    div [ Style.classes.addView ]
        [ div [ Style.classes.addElement ]
            [ HtmlUtil.searchAreaWith
                { msg = Page.SetComplexFoodsSearchString
                , searchString = model.complexIngredientsGroup.foodsSearchString
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
                    (viewComplexFoods
                        |> Paginate.page
                        |> List.map (viewComplexFoodLine model.allRecipes model.complexIngredientsGroup.foods model.complexIngredientsGroup.foodsToAdd model.complexIngredientsGroup.ingredients)
                    )
                ]
            , div [ Style.classes.pagination ]
                [ ViewUtil.pagerButtons
                    { msg =
                        PaginationSettings.updateCurrentPage
                            { pagination = Page.lenses.complexIngredientsGroup |> Compose.lensWithLens FoodGroup.lenses.pagination
                            , items = Pagination.lenses.foods
                            }
                            model
                            >> Page.SetComplexIngredientsPagination
                    , elements = viewComplexFoods
                    }
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
        [ td [ Style.classes.editable, onClick editMsg ] [ label [] [ text <| DictUtil.nameOrEmpty foodMap <| ingredient.foodId ] ]
        , td [ Style.classes.editable, Style.classes.numberLabel, onClick editMsg ] [ label [] [ text <| String.fromFloat <| ingredient.amountUnit.factor ] ]
        , td [ Style.classes.editable, Style.classes.numberLabel, onClick editMsg ] [ label [] [ text <| DictUtil.nameOrEmpty measureMap <| ingredient.amountUnit.measureId ] ]
        , td [ Style.classes.controls ] [ button [ Style.classes.button.edit, onClick editMsg ] [ text "Edit" ] ]
        , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.DeleteIngredient ingredient.id) ] [ text "Delete" ] ]
        ]


editOrDeleteComplexIngredientLine : Page.RecipeMap -> Page.ComplexFoodMap -> ComplexIngredient -> Html Page.Msg
editOrDeleteComplexIngredientLine recipeMap complexFoodMap complexIngredient =
    let
        editMsg =
            Page.EnterEditComplexIngredient complexIngredient.complexFoodId

        info =
            complexFoodInfo complexIngredient.complexFoodId recipeMap complexFoodMap
    in
    tr [ Style.classes.editing ]
        [ td [ Style.classes.editable, onClick editMsg ] [ label [] [ text <| info.name ] ]
        , td [ Style.classes.editable, Style.classes.numberLabel, onClick editMsg ] [ label [] [ text <| String.fromFloat <| complexIngredient.factor ] ]
        , td [ Style.classes.editable, Style.classes.numberLabel, onClick editMsg ] [ label [] [ text <| info.amount ] ]
        , td [ Style.classes.controls ] [ button [ Style.classes.button.edit, onClick editMsg ] [ text "Edit" ] ]
        , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.DeleteComplexIngredient complexIngredient.complexFoodId) ] [ text "Delete" ] ]
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
        [ td [] [ label [] [ text <| DictUtil.nameOrEmpty foodMap <| ingredient.foodId ] ]
        , td [ Style.classes.numberCell ]
            [ input
                [ value
                    ingredientUpdateClientInput.amountUnit.factor.text
                , onInput
                    (flip
                        (ValidatedInput.lift
                            (IngredientUpdateClientInput.lenses.amountUnit
                                |> Compose.lensWithLens AmountUnitClientInput.lenses.factor
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


editComplexIngredientLine : Page.RecipeMap -> Page.ComplexFoodMap -> ComplexIngredient -> ComplexIngredientClientInput -> Html Page.Msg
editComplexIngredientLine recipeMap complexFoodMap complexIngredient complexIngredientUpdateClientInput =
    let
        saveMsg =
            Page.SaveComplexIngredientEdit complexIngredientUpdateClientInput

        cancelMsg =
            Page.ExitEditComplexIngredientAt complexIngredient.complexFoodId

        info =
            complexFoodInfo complexIngredient.complexFoodId recipeMap complexFoodMap
    in
    tr [ Style.classes.editLine ]
        [ td [] [ label [] [ text <| info.name ] ]
        , td [ Style.classes.numberCell ]
            [ input
                [ value
                    complexIngredientUpdateClientInput.factor.text
                , onInput
                    (flip
                        (ValidatedInput.lift
                            ComplexIngredientClientInput.lenses.factor
                        ).set
                        complexIngredientUpdateClientInput
                        >> Page.UpdateComplexIngredient
                    )
                , onEnter saveMsg
                , HtmlUtil.onEscape cancelMsg
                , Style.classes.numberLabel
                ]
                []
            ]
        , td [ Style.classes.numberCell ]
            [ label [ Style.classes.editable, Style.classes.numberLabel ] [ text <| info.amount ]
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
startingDropdownUnit measureMap measureId =
    { value = String.fromInt measureId
    , text = DictUtil.nameOrEmpty measureMap measureId
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
        >> flip (ps.amountUnitLens |> Compose.lensWithLens AmountUnitClientInput.lenses.measureId).set ps.input
        >> ps.mkMsg


type alias ComplexFoodInfo =
    { name : String
    , amount : String
    }


complexFoodInfo : ComplexFoodId -> Page.RecipeMap -> Page.ComplexFoodMap -> ComplexFoodInfo
complexFoodInfo complexFoodId recipeMap complexFoodMap =
    { name = recipeMap |> flip DictUtil.nameOrEmpty complexFoodId
    , amount =
        complexFoodMap
            |> Dict.get complexFoodId
            |> Maybe.Extra.unwrap "" (\complexFood -> String.concat [ complexFood.amount |> String.fromFloat, complexFood.unit |> ComplexFoodUnit.toPrettyString ])
    }


viewFoodLine : Page.FoodMap -> Page.AddFoodsMap -> Page.PlainIngredientOrUpdateMap -> Food -> Html Page.Msg
viewFoodLine foodMap ingredientsToAdd ingredients food =
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

                        ( confirmName, confirmMsg, confirmStyle ) =
                            case DictUtil.firstSuch (\ingredient -> Editing.field .foodId ingredient == ingredientToAdd.foodId) ingredients of
                                Nothing ->
                                    ( "Add", addMsg, Style.classes.button.confirm )

                                Just ingredientOrUpdate ->
                                    ( "Update"
                                    , ingredientOrUpdate
                                        |> Editing.field identity
                                        |> IngredientUpdateClientInput.from
                                        |> IngredientUpdateClientInput.lenses.amountUnit.set ingredientToAdd.amountUnit
                                        |> Page.SaveIngredientEdit
                                    , Style.classes.button.edit
                                    )
                    in
                    [ td [ Style.classes.numberCell ]
                        [ input
                            ([ value ingredientToAdd.amountUnit.factor.text
                             , onInput
                                (flip
                                    (ValidatedInput.lift
                                        (IngredientCreationClientInput.amountUnit
                                            |> Compose.lensWithLens AmountUnitClientInput.lenses.factor
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
                            , emptyItem = Nothing
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
                            [ confirmStyle
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


viewComplexFoodLine : Page.RecipeMap -> Page.ComplexFoodMap -> Page.AddComplexFoodsMap -> Page.ComplexIngredientOrUpdateMap -> ComplexFood -> Html Page.Msg
viewComplexFoodLine recipeMap complexFoodMap complexIngredientsToAdd complexIngredients complexFood =
    let
        addMsg =
            Page.AddComplexFood complexFood.recipeId

        selectMsg =
            Page.SelectComplexFood complexFood

        cancelMsg =
            Page.DeselectComplexFood complexFood.recipeId

        maybeComplexIngredientToAdd =
            Dict.get complexFood.recipeId complexIngredientsToAdd

        rowClickAction =
            if Maybe.Extra.isJust maybeComplexIngredientToAdd then
                []

            else
                [ onClick selectMsg ]

        info =
            complexFoodInfo complexFood.recipeId recipeMap complexFoodMap

        process =
            case maybeComplexIngredientToAdd of
                Nothing ->
                    [ td [ Style.classes.editable, Style.classes.numberCell ] []
                    , td [ Style.classes.editable, Style.classes.numberCell ] []
                    , td [ Style.classes.controls ] []
                    , td [ Style.classes.controls ] [ button [ Style.classes.button.select, onClick selectMsg ] [ text "Select" ] ]
                    ]

                Just complexIngredientToAdd ->
                    let
                        validInput =
                            complexIngredientToAdd.factor |> ValidatedInput.isValid

                        ( confirmName, confirmMsg, confirmStyle ) =
                            case DictUtil.firstSuch (\complexIngredient -> Editing.field .complexFoodId complexIngredient == complexIngredientToAdd.complexFoodId) complexIngredients of
                                Nothing ->
                                    ( "Add", addMsg, Style.classes.button.confirm )

                                Just ingredientOrUpdate ->
                                    ( "Update"
                                    , ingredientOrUpdate
                                        |> Editing.field identity
                                        |> ComplexIngredientClientInput.from
                                        |> ComplexIngredientClientInput.lenses.factor.set complexIngredientToAdd.factor
                                        |> Page.SaveComplexIngredientEdit
                                    , Style.classes.button.edit
                                    )
                    in
                    [ td [ Style.classes.numberCell ]
                        [ input
                            ([ value complexIngredientToAdd.factor.text
                             , onInput
                                (flip
                                    (ValidatedInput.lift
                                        ComplexIngredientClientInput.lenses.factor
                                    ).set
                                    complexIngredientToAdd
                                    >> Page.UpdateAddComplexFood
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
                    , td [ Style.classes.editable, Style.classes.numberLabel, onClick selectMsg ] [ label [] [ text <| info.amount ] ]
                    , td [ Style.classes.controls ]
                        [ button
                            [ confirmStyle
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
        (td [ Style.classes.editable ] [ label [] [ text info.name ] ]
            :: process
        )


anySelection : Lens Page.Model (FoodGroup ingredientId ingredient update foodId food creation) -> Page.Model -> Bool
anySelection foodGroupLens =
    (foodGroupLens |> Compose.lensWithLens FoodGroup.lenses.foodsToAdd).get
        >> Dict.isEmpty
        >> not
