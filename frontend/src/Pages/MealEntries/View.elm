module Pages.MealEntries.View exposing (view)

import Api.Types.MealEntry exposing (MealEntry)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Dict
import Either
import Html exposing (Html, button, div, input, label, td, text, thead, tr)
import Html.Attributes exposing (class, disabled, id, value)
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
        in
        div [ id "mealEntry" ]
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
                        , td [] [ label [] [ text "Number of servings" ] ]
                        ]
                    ]
                    :: viewEditMealEntries
                        (model.mealEntries
                            |> Dict.values
                            |> List.sortBy (Editing.field .recipeId >> Page.recipeNameOrEmpty model.recipes >> String.toLower)
                        )
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
        , td [] [ label [] [ text (mealEntry.numberOfServings |> String.fromFloat) ] ]
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


viewRecipeLine : Page.AddMealEntriesMap -> Page.MealEntryOrUpdateMap -> Recipe -> Html Page.Msg
viewRecipeLine mealEntriesToAdd mealEntries recipe =
    let
        addMsg =
            Page.AddRecipe recipe.id

        process =
            case Dict.get recipe.id mealEntriesToAdd of
                Nothing ->
                    [ td [] [ button [ class "button", onClick (Page.SelectRecipe recipe.id) ] [ text "Select" ] ] ]

                Just mealEntryToAdd ->
                    [ td []
                        [ label [] [ text "Amount" ]
                        , input
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
                            ]
                            []
                        ]
                    , td []
                        [ button
                            [ class "button"
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
                    , td [] [ button [ class "button", onClick (Page.DeselectRecipe recipe.id) ] [ text "Cancel" ] ]
                    ]
    in
    tr [ id "addingRecipeLine" ]
        (td [] [ label [] [ text recipe.name ] ]
            :: td [] [ label [] [ text <| Maybe.withDefault "" <| recipe.description ] ]
            :: process
        )
