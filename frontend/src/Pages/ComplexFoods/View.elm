module Pages.ComplexFoods.View exposing (..)

import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ComplexFoodUnit as ComplexFoodUnit exposing (ComplexFoodUnit)
import Api.Types.Recipe exposing (Recipe)
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
import Pages.ComplexFoods.ComplexFoodClientInput as ComplexFoodClientInput exposing (ComplexFoodClientInput)
import Pages.ComplexFoods.Page as Page
import Pages.ComplexFoods.Pagination as Pagination
import Pages.ComplexFoods.Status as Status
import Pages.Util.DictUtil as DictUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)
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
        , currentPage = Just ViewUtil.ComplexFoods
        , showNavigation = True
        }
        model
    <|
        let
            viewEditComplexFood =
                Either.unpack
                    (editOrDeleteComplexFoodLine model.recipes)
                    (\e -> e.update |> editComplexFoodLine model.recipes e.original)

            viewEditComplexFoods =
                model.complexFoods
                    |> Dict.values
                    |> List.sortBy (Editing.field .recipeId >> Page.complexFoodNameOrEmpty model.recipes >> String.toLower)
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.pagination |> Compose.lensWithLens Pagination.lenses.complexFoods
                        }
                        model

            viewRecipes =
                model.recipes
                    |> Dict.filter (\_ v -> SearchUtil.search model.recipesSearchString v.name)
                    |> Dict.values
                    |> List.sortBy .name
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.pagination |> Compose.lensWithLens Pagination.lenses.recipes
                        }
                        model

            anySelection =
                model.complexFoodsToCreate
                    |> Dict.isEmpty
                    |> not

            ( amount, unit ) =
                if anySelection then
                    ( "Amount", "Unit" )

                else
                    ( "", "" )
        in
        div [ Style.ids.complexFoodEditor ]
            [ div [ Style.classes.elements ] [ label [] [ text "Complex foods" ] ]
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
                        (viewEditComplexFoods
                            |> Paginate.page
                            |> List.map viewEditComplexFood
                        )
                    ]
                , div [ Style.classes.pagination ]
                    [ ViewUtil.pagerButtons
                        { msg =
                            PaginationSettings.updateCurrentPage
                                { pagination = Page.lenses.pagination
                                , items = Pagination.lenses.complexFoods
                                }
                                model
                                >> Page.SetPagination
                        , elements = viewEditComplexFoods
                        }
                    ]
                ]
            , div [ Style.classes.addView ]
                [ div [ Style.classes.addElement ]
                    [ HtmlUtil.searchAreaWith
                        { msg = Page.SetRecipesSearchString
                        , searchString = model.recipesSearchString
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
                            (viewRecipes
                                |> Paginate.page
                                |> List.map (viewRecipeLine model.complexFoodsToCreate model.complexFoods)
                            )
                        ]
                    , div [ Style.classes.pagination ]
                        [ ViewUtil.pagerButtons
                            { msg =
                                PaginationSettings.updateCurrentPage
                                    { pagination = Page.lenses.pagination
                                    , items = Pagination.lenses.recipes
                                    }
                                    model
                                    >> Page.SetPagination
                            , elements = viewRecipes
                            }
                        ]
                    ]
                ]
            ]


editOrDeleteComplexFoodLine : Page.RecipeMap -> ComplexFood -> Html Page.Msg
editOrDeleteComplexFoodLine recipeMap complexFood =
    let
        editMsg =
            Page.EnterEditComplexFood complexFood.recipeId
    in
    tr [ Style.classes.editing ]
        [ td [ Style.classes.editable, onClick editMsg ] [ label [] [ text <| Page.complexFoodNameOrEmpty recipeMap <| complexFood.recipeId ] ]
        , td [ Style.classes.editable, Style.classes.numberLabel, onClick editMsg ] [ label [] [ text <| String.fromFloat <| complexFood.amount ] ]
        , td [ Style.classes.editable, Style.classes.numberLabel, onClick editMsg ] [ label [] [ text <| ComplexFoodUnit.toPrettyString <| complexFood.unit ] ]
        , td [ Style.classes.controls ] [ button [ Style.classes.button.edit, onClick editMsg ] [ text "Edit" ] ]
        , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.DeleteComplexFood complexFood.recipeId) ] [ text "Delete" ] ]
        ]


editComplexFoodLine : Page.RecipeMap -> ComplexFood -> ComplexFoodClientInput -> Html Page.Msg
editComplexFoodLine recipeMap complexFood complexFoodClientInput =
    let
        saveMsg =
            Page.SaveComplexFoodEdit complexFoodClientInput

        cancelMsg =
            Page.ExitEditComplexFood complexFood.recipeId
    in
    tr [ Style.classes.editLine ]
        [ td [] [ label [] [ text <| Page.complexFoodNameOrEmpty recipeMap <| complexFood.recipeId ] ]
        , td [ Style.classes.numberCell ]
            [ input
                [ value
                    complexFoodClientInput.amount.text
                , onInput
                    (flip
                        (ValidatedInput.lift
                            ComplexFoodClientInput.lenses.amount
                        ).set
                        complexFoodClientInput
                        >> Page.UpdateComplexFood
                    )
                , onEnter saveMsg
                , HtmlUtil.onEscape cancelMsg
                , Style.classes.numberLabel
                ]
                []
            ]
        , td [ Style.classes.numberCell ]
            [ dropdown
                { items = units
                , emptyItem =
                    complexFood.unit |> unitToItem |> Just
                , onChange =
                    onChangeDropdown
                        { mkMsg = Page.UpdateComplexFood
                        , input = complexFoodClientInput
                        }
                }
                [ Style.classes.numberLabel, HtmlUtil.onEscape cancelMsg ]
                (complexFood.unit
                    |> ComplexFoodUnit.toString
                    |> Just
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


onChangeDropdown :
    { input : ComplexFoodClientInput
    , mkMsg : ComplexFoodClientInput -> Page.Msg
    }
    -> Maybe String
    -> Page.Msg
onChangeDropdown ps =
    Maybe.andThen ComplexFoodUnit.fromString
        >> Maybe.withDefault ps.input.unit
        >> flip ComplexFoodClientInput.lenses.unit.set ps.input
        >> ps.mkMsg


viewRecipeLine : Page.CreateComplexFoodsMap -> Page.ComplexFoodOrUpdateMap -> Recipe -> Html Page.Msg
viewRecipeLine complexFoodsToCreate complexFoods recipe =
    let
        createMsg =
            Page.CreateComplexFood recipe.id

        selectMsg =
            Page.SelectRecipe recipe

        cancelMsg =
            Page.DeselectRecipe recipe.id

        maybeComplexFoodToAdd =
            Dict.get recipe.id complexFoodsToCreate

        rowClickAction =
            if Maybe.Extra.isJust maybeComplexFoodToAdd then
                []

            else
                [ onClick selectMsg ]

        process =
            case maybeComplexFoodToAdd of
                Nothing ->
                    [ td [ Style.classes.editable, Style.classes.numberCell ] []
                    , td [ Style.classes.editable, Style.classes.numberCell ] []
                    , td [ Style.classes.controls ] []
                    , td [ Style.classes.controls ] [ button [ Style.classes.button.select, onClick selectMsg ] [ text "Select" ] ]
                    ]

                Just complexFoodToAdd ->
                    let
                        validInput =
                            complexFoodToAdd.amount |> ValidatedInput.isValid

                        ( confirmName, confirmMsg, confirmStyle ) =
                            case DictUtil.firstSuch (\complexFood -> Editing.field .recipeId complexFood == complexFoodToAdd.recipeId) complexFoods of
                                Nothing ->
                                    ( "Add", createMsg, Style.classes.button.confirm )

                                Just complexFoodOrUpdate ->
                                    ( "Update"
                                    , complexFoodOrUpdate
                                        |> Editing.field identity
                                        |> ComplexFoodClientInput.from
                                        |> ComplexFoodClientInput.lenses.amount.set complexFoodToAdd.amount
                                        |> ComplexFoodClientInput.lenses.unit.set complexFoodToAdd.unit
                                        |> Page.SaveComplexFoodEdit
                                    , Style.classes.button.edit
                                    )
                    in
                    [ td [ Style.classes.numberCell ]
                        [ input
                            ([ value complexFoodToAdd.amount.text
                             , onInput
                                (flip
                                    (ValidatedInput.lift
                                        ComplexFoodClientInput.lenses.amount
                                    ).set
                                    complexFoodToAdd
                                    >> Page.UpdateComplexFoodCreation
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
                            { items = units
                            , emptyItem = Nothing
                            , onChange =
                                onChangeDropdown
                                    { mkMsg = Page.UpdateComplexFoodCreation
                                    , input = complexFoodToAdd
                                    }
                            }
                            [ Style.classes.numberLabel
                            , HtmlUtil.onEscape cancelMsg
                            ]
                            (complexFoodToAdd.unit |> ComplexFoodUnit.toString |> Just)
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
        (td [ Style.classes.editable ] [ label [] [ text recipe.name ] ]
            :: process
        )


unitToItem : ComplexFoodUnit -> Item
unitToItem complexFoodUnit =
    { value = complexFoodUnit |> ComplexFoodUnit.toString
    , text = complexFoodUnit |> ComplexFoodUnit.toPrettyString
    , enabled = True
    }


units : List Item
units =
    [ ComplexFoodUnit.G, ComplexFoodUnit.ML ]
        |> List.map unitToItem
