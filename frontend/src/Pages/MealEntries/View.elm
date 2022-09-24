module Pages.MealEntries.View exposing (view)

import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Dict
import Either
import Html exposing (Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, colspan, disabled, id, scope, value)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Pages.MealEntries.MealEntryCreationClientInput as MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntries.MealEntryUpdateClientInput as MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Pages.MealEntries.Page as Page exposing (RecipeMap)
import Pages.MealEntries.Status as Status
import Pages.Util.DateUtil as DateUtil
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
            viewEditMealEntries =
                List.map
                    (Either.unpack
                        (editOrDeleteMealEntryLine model.recipes)
                        (\e -> e.update |> editMealEntryLine model.recipes e.original)
                    )

            viewRecipes searchString =
                model.recipes
                    |> Dict.filter (\_ v -> SearchUtil.search searchString v.name)
                    |> Dict.values
                    |> List.sortBy .name
                    |> List.map (viewRecipeLine model.mealEntriesToAdd model.mealEntries)

            anySelection =
                model.mealEntriesToAdd
                    |> Dict.isEmpty
                    |> not

            numberOfServings =
                if anySelection then
                    "Servings"

                else
                    ""
        in
        div [ id "mealEntryEditor" ]
            [ div []
                [ table [ class "info" ]
                    [ tr []
                        [ td [ class "descriptionColumn" ] [ label [] [ text "Date" ] ]
                        , td [] [ label [] [ text <| Maybe.Extra.unwrap "" (.date >> DateUtil.toString) <| model.mealInfo ] ]
                        ]
                    , tr []
                        [ td [ class "descriptionColumn" ] [ label [] [ text "Name" ] ]
                        , td [] [ label [] [ text <| Maybe.withDefault "" <| Maybe.andThen .name <| model.mealInfo ] ]
                        ]
                    ]
                ]
            , div [ class "elements" ] [ label [] [ text "Dishes" ] ]
            , div [ class "choices" ]
                [ table []
                    [ colgroup []
                        [ col [] []
                        , col [] []
                        , col [] []
                        , col [ stringProperty "span" "2" ] []
                        ]
                    , thead []
                        [ tr []
                            [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                            , th [ scope "col" ] [ label [] [ text "Description" ] ]
                            , th [ scope "col", class "numberLabel" ] [ label [] [ text "Servings" ] ]
                            , th [ colspan 2, scope "colgroup", class "controlsGroup" ] []
                            ]
                        ]
                    , tbody []
                        (viewEditMealEntries
                            (model.mealEntries
                                |> Dict.values
                                |> List.sortBy (Editing.field .recipeId >> Page.recipeNameOrEmpty model.recipes >> String.toLower)
                            )
                        )
                    ]
                ]
            , div [ class "addView" ]
                [ div [ class "addMealEntry" ]
                    [ div [ class "searchArea" ]
                        [ label [] [ text Links.lookingGlass ]
                        , input
                            [ onInput Page.SetRecipesSearchString
                            , value <| model.recipesSearchString
                            , class "searchField"
                            ]
                            []
                        , button
                            [ class "cancelButton"
                            , onClick (Page.SetRecipesSearchString "")
                            , disabled <| String.isEmpty <| model.recipesSearchString
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
                                , th [ scope "col" ] [ label [] [ text "Description" ] ]
                                , th [ scope "col", class "numberLabel" ] [ label [] [ text numberOfServings ] ]
                                , th [ colspan 2, scope "colgroup", class "controlsGroup" ] []
                                ]
                            ]
                        , tbody [] (viewRecipes model.recipesSearchString)
                        ]
                    ]
                ]
            ]


editOrDeleteMealEntryLine : Page.RecipeMap -> MealEntry -> Html Page.Msg
editOrDeleteMealEntryLine recipeMap mealEntry =
    tr [ class "editing" ]
        [ td [ class "editable" ] [ label [] [ text <| Page.recipeNameOrEmpty recipeMap <| mealEntry.recipeId ] ]
        , td [ class "editable" ] [ label [] [ text <| Page.descriptionOrEmpty recipeMap <| mealEntry.recipeId ] ]
        , td [ class "editable", class "numberLabel" ] [ label [] [ text <| String.fromFloat <| mealEntry.numberOfServings ] ]
        , td [ class "controls" ] [ button [ class "editButton", onClick (Page.EnterEditMealEntry mealEntry.id) ] [ text "Edit" ] ]
        , td [ class "controls" ] [ button [ class "deleteButton", onClick (Page.DeleteMealEntry mealEntry.id) ] [ text "Delete" ] ]
        ]


editMealEntryLine : Page.RecipeMap -> MealEntry -> MealEntryUpdateClientInput -> Html Page.Msg
editMealEntryLine recipeMap mealEntry mealEntryUpdateClientInput =
    tr [ class "editLine" ]
        [ td [] [ label [] [ text <| Page.recipeNameOrEmpty recipeMap <| mealEntry.recipeId ] ]
        , td [] [ label [] [ text <| Page.descriptionOrEmpty recipeMap <| mealEntry.recipeId ] ]
        , td [ class "numberCell" ]
            [ input
                [ value
                    (mealEntryUpdateClientInput.numberOfServings.value
                        |> String.fromFloat
                    )
                , onInput
                    (flip
                        (ValidatedInput.lift
                            MealEntryUpdateClientInput.lenses.numberOfServings
                        ).set
                        mealEntryUpdateClientInput
                        >> Page.UpdateMealEntry
                    )
                , onEnter (Page.SaveMealEntryEdit mealEntry.id)
                , class "numberLabel"
                ]
                []
            ]
        , td []
            [ button [ class "confirmButton", onClick (Page.SaveMealEntryEdit mealEntry.id) ]
                [ text "Save" ]
            ]
        , td []
            [ button [ class "cancelButton", onClick (Page.ExitEditMealEntryAt mealEntry.id) ]
                [ text "Cancel" ]
            ]
        ]


viewRecipeLine : Page.AddMealEntriesMap -> Page.MealEntryOrUpdateMap -> Recipe -> Html Page.Msg
viewRecipeLine mealEntriesToAdd mealEntries recipe =
    let
        addMsg =
            Page.AddRecipe recipe.id

        process =
            case Dict.get recipe.id mealEntriesToAdd of
                Nothing ->
                    [ td [ class "editable", class "numberCell" ] []
                    , td [ class "controls" ] []
                    , td [ class "controls" ] [ button [ class "selectButton", onClick (Page.SelectRecipe recipe.id) ] [ text "Select" ] ]
                    ]

                Just mealEntryToAdd ->
                    [ td [ class "numberCell" ]
                        [ input
                            [ value mealEntryToAdd.numberOfServings.text
                            , onInput
                                (flip
                                    (ValidatedInput.lift
                                        MealEntryCreationClientInput.lenses.numberOfServings
                                    ).set
                                    mealEntryToAdd
                                    >> Page.UpdateAddRecipe
                                )
                            , onEnter addMsg
                            , class "numberLabel"
                            ]
                            []
                        ]
                    , td [ class "controls" ]
                        [ button
                            [ class "confirmButton"
                            , disabled
                                (mealEntryToAdd.numberOfServings |> ValidatedInput.isValid |> not)
                            , onClick addMsg
                            ]
                            [ text
                                (if DictUtil.existsValue (\mealEntry -> Editing.field .recipeId mealEntry == mealEntryToAdd.recipeId) mealEntries then
                                    "Update"

                                 else
                                    "Add"
                                )
                            ]
                        ]
                    , td [ class "controls" ] [ button [ class "cancelButton", onClick (Page.DeselectRecipe recipe.id) ] [ text "Cancel" ] ]
                    ]
    in
    tr [ class "editing" ]
        (td [] [ label [] [ text recipe.name ] ]
            :: td [] [ label [] [ text <| Maybe.withDefault "" <| recipe.description ] ]
            :: process
        )
