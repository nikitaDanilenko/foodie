module Pages.MealEntryEditor.View exposing (view)

import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Dict
import Either
import Html exposing (Html, button, div, input, label, td, text, thead, tr)
import Html.Attributes exposing (class, disabled, id, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import List.Extra
import Maybe.Extra
import Pages.MealEntryEditor.MealEntryCreationClientInput as MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntryEditor.MealEntryUpdateClientInput as MealEntryUpdateClientInput exposing (MealEntryUpdateClientInput)
import Pages.MealEntryEditor.Page as Page exposing (RecipeMap)
import Pages.Util.DateUtil as DateUtil
import Pages.Util.Links as Links
import Pages.Util.ValidatedInput as ValidatedInput


view : Page.Model -> Html Page.Msg
view model =
    let
        viewEditMealEntries =
            List.map
                (Either.unpack
                    (editOrDeleteMealEntryLine model.recipes)
                    (\e -> e.update |> editMealEntryLine model.recipes e.original)
                )

        viewRecipes searchString =
            model.recipes
                |> Dict.filter (\_ v -> String.contains (String.toLower searchString) (String.toLower v.name))
                |> Dict.values
                |> List.sortBy .name
                |> List.map (viewRecipeLine model.mealEntriesToAdd)
    in
    div [ id "mealEntryEditor" ]
        [ div [ id "mealInfo" ]
            [ label [] [ text "Date" ]
            , label [] [ text <| Maybe.Extra.unwrap "" (.date >> DateUtil.toString) <| model.mealInfo ]
            , label [] [ text "Name" ]
            , label [] [ text <| Maybe.withDefault "" <| Maybe.andThen .name <| model.mealInfo ]
            ]
        , div [ id "mealEntryView" ]
            (thead []
                [ tr []
                    [ td [] [ label [] [ text "Name" ] ]
                    , td [] [ label [] [ text "Amount" ] ]
                    ]
                ]
                :: viewEditMealEntries model.mealEntries
            )
        , div [ id "addMealEntryView" ]
            (div [ id "addMealEntry" ]
                [ div [ id "searchField" ]
                    [ label [] [ text Links.lookingGlass ]
                    , input [ onInput Page.SetRecipesSearchString ] []
                    ]
                ]
                :: thead []
                    [ tr []
                        [ td [] [ label [] [ text "Name" ] ]
                        , td [] [ label [] [ text "Description" ] ]
                        ]
                    ]
                :: viewRecipes model.recipesSearchString
            )
        ]


editOrDeleteMealEntryLine : Page.RecipeMap -> MealEntry -> Html Page.Msg
editOrDeleteMealEntryLine recipeMap mealEntry =
    tr [ id "editingMealEntry" ]
        [ td [] [ label [] [ text (mealEntry.recipeId |> Page.recipeNameOrEmpty recipeMap) ] ]
        , td [] [ label [] [ text (mealEntry.factor |> String.fromFloat) ] ]
        , td [] [ button [ class "button", onClick (Page.EnterEditMealEntry mealEntry.id) ] [ text "Edit" ] ]
        , td [] [ button [ class "button", onClick (Page.DeleteMealEntry mealEntry.id) ] [ text "Delete" ] ]
        ]


editMealEntryLine : Page.RecipeMap -> MealEntry -> MealEntryUpdateClientInput -> Html Page.Msg
editMealEntryLine recipeMap mealEntry mealEntryUpdateClientInput =
    tr [ id "mealEntryLine" ]
        [ td [] [ label [] [ text (mealEntry.recipeId |> Page.recipeNameOrEmpty recipeMap) ] ]
        , td []
            [ input
                [ value
                    (mealEntryUpdateClientInput.factor.value
                        |> String.fromFloat
                    )
                , onInput
                    (flip
                        (ValidatedInput.lift
                            MealEntryUpdateClientInput.lenses.factor
                        ).set
                        mealEntryUpdateClientInput
                        >> Page.UpdateMealEntry
                    )
                , onEnter (Page.SaveMealEntryEdit mealEntry.id)
                ]
                []
            ]
        , td []
            [ button [ class "button", onClick (Page.SaveMealEntryEdit mealEntry.id) ]
                [ text "Save" ]
            ]
        , td []
            [ button [ class "button", onClick (Page.ExitEditMealEntryAt mealEntry.id) ]
                [ text "Cancel" ]
            ]
        ]


viewRecipeLine : List MealEntryCreationClientInput -> Recipe -> Html Page.Msg
viewRecipeLine mealEntriesToAdd recipe =
    let
        addMsg =
            Page.AddRecipe recipe.id

        process =
            case List.Extra.find (\me -> me.recipeId == recipe.id) mealEntriesToAdd of
                Nothing ->
                    [ td [] [ button [ class "button", onClick (Page.SelectRecipe recipe.id) ] [ text "Select" ] ] ]

                Just mealEntryToAdd ->
                    [ td []
                        [ label [] [ text "Amount" ]
                        , input
                            [ value mealEntryToAdd.factor.text
                            , onInput
                                (flip
                                    (ValidatedInput.lift
                                        MealEntryCreationClientInput.lenses.factor
                                    ).set
                                    mealEntryToAdd
                                    >> Page.UpdateAddRecipe
                                )
                            , onEnter addMsg
                            ]
                            []
                        ]
                    , td []
                        [ button
                            [ class "button"
                            , disabled
                                (List.Extra.find (\me -> me.recipeId == recipe.id) mealEntriesToAdd
                                    |> Maybe.Extra.unwrap True (.factor >> ValidatedInput.isValid >> not)
                                )
                            , onClick addMsg
                            ]
                            [ text "Add" ]
                        ]
                    , td [] [ button [ class "button", onClick (Page.DeselectRecipe recipe.id) ] [ text "Cancel" ] ]
                    ]
    in
    tr [ id "addingRecipeLine" ]
        (td [] [ label [] [ text recipe.name ] ]
            :: td [] [ label [] [ text <| Maybe.withDefault "" <| recipe.description ] ]
            :: process
        )
