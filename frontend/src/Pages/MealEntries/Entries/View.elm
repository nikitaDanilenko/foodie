module Pages.MealEntries.Entries.View exposing (..)

import Api.Auxiliary exposing (RecipeId)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Html exposing (Html, button, input, label, td, text, th)
import Html.Attributes exposing (disabled, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import List.Extra
import Maybe.Extra
import Pages.MealEntries.Entries.Page as Page
import Pages.MealEntries.MealEntryCreationClientInput as MealEntryCreationClientInput exposing (MealEntryCreationClientInput)
import Pages.MealEntries.MealEntryUpdateClientInput as MealEntryUpdateClientInput
import Pages.Recipes.View
import Pages.Util.Choice.Page
import Pages.Util.Choice.View
import Pages.Util.DictListUtil as DictListUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.NavigationUtil as NavigationUtil
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput
import Util.DictList as DictList exposing (DictList)
import Util.Editing as Editing exposing (Editing)
import Util.MaybeUtil as MaybeUtil
import Util.SearchUtil as SearchUtil


viewMealEntries : Page.Main -> Html Page.LogicMsg
viewMealEntries main =
    Pages.Util.Choice.View.viewElements
        { nameOfChoice = .name
        , choiceIdOfElement = .recipeId
        , idOfElement = .id
        , elementHeaderColumns =
            [ th [] [ label [] [ text "Name" ] ]
            , th [] [ label [] [ text "Description" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Serving size" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Servings" ] ]
            ]
        , info =
            \mealEntry ->
                { display =
                    recipeInfoFromMap main.choices mealEntry.recipeId
                        ++ [ { attributes = [ Style.classes.editable, Style.classes.numberLabel ]
                             , children = [ label [] [ text <| String.fromFloat <| mealEntry.numberOfServings ] ]
                             }
                           ]
                , controls =
                    [ td [ Style.classes.controls ] [ button [ Style.classes.button.edit, onClick <| Pages.Util.Choice.Page.EnterEdit <| mealEntry.id ] [ text "Edit" ] ]
                    , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick <| Pages.Util.Choice.Page.RequestDelete <| mealEntry.id ] [ text "Delete" ] ]
                    , td [ Style.classes.controls ] [ NavigationUtil.recipeEditorLinkButton mealEntry.recipeId ]
                    ]
                }
        , isValidInput = .numberOfServings >> ValidatedInput.isValid
        , edit =
            \mealEntry mealEntryUpdateClientInput ->
                recipeInfoFromMap main.choices mealEntry.recipeId
                    ++ [ { attributes = [ Style.classes.numberCell ]
                         , children =
                            [ input
                                [ value
                                    mealEntryUpdateClientInput.numberOfServings.text
                                , onInput
                                    (flip
                                        (ValidatedInput.lift
                                            MealEntryUpdateClientInput.lenses.numberOfServings
                                        ).set
                                        mealEntryUpdateClientInput
                                        >> Pages.Util.Choice.Page.Edit mealEntry.id
                                    )
                                , Style.classes.numberLabel
                                ]
                                []
                            ]
                         }
                       ]
        }
        main


viewRecipes : Page.Main -> Html Page.LogicMsg
viewRecipes main =
    let
        numberOfServings =
            if DictListUtil.existsValue Editing.isUpdate main.choices then
                "Servings"

            else
                ""
    in
    Pages.Util.Choice.View.viewChoices
        { matchesSearchText = \string recipe -> SearchUtil.search string recipe.name || SearchUtil.search string (recipe.description |> Maybe.withDefault "")
        , sortBy = .name
        , choiceHeaderColumns =
            [ th [] [ label [] [ text "Name" ] ]
            , th [] [ label [] [ text "Description" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Serving size" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text numberOfServings ] ]
            ]
        , idOfChoice = .id
        , elementCreationLine =
            \recipe creation ->
                let
                    validInput =
                        creation.numberOfServings |> ValidatedInput.isValid

                    addMsg =
                        Pages.Util.Choice.Page.Create recipe.id

                    cancelMsg =
                        Pages.Util.Choice.Page.DeselectChoice recipe.id

                    ( confirmName, confirmStyle ) =
                        if DictListUtil.existsValue (\mealEntry -> mealEntry.original.recipeId == creation.recipeId) main.elements then
                            ( "Add again", Style.classes.button.edit )

                        else
                            ( "Add", Style.classes.button.confirm )
                in
                { display =
                    recipeInfo recipe
                        ++ [ { attributes = [ Style.classes.numberLabel ]
                             , children =
                                [ input
                                    ([ MaybeUtil.defined <| value creation.numberOfServings.text
                                     , MaybeUtil.defined <|
                                        onInput <|
                                            flip
                                                (ValidatedInput.lift
                                                    MealEntryCreationClientInput.lenses.numberOfServings
                                                ).set
                                                creation
                                                >> Pages.Util.Choice.Page.UpdateCreation
                                     , MaybeUtil.defined <| Style.classes.numberLabel
                                     , MaybeUtil.defined <| HtmlUtil.onEscape <| cancelMsg
                                     , MaybeUtil.optional validInput <| onEnter <| addMsg
                                     ]
                                        |> Maybe.Extra.values
                                    )
                                    []
                                ]
                             }
                           ]
                , controls =
                    [ td [ Style.classes.controls ]
                        [ button
                            ([ MaybeUtil.defined <| confirmStyle
                             , MaybeUtil.defined <| disabled <| not <| validInput
                             , MaybeUtil.optional validInput <| onClick addMsg
                             ]
                                |> Maybe.Extra.values
                            )
                            [ text confirmName ]
                        ]
                    , td [ Style.classes.controls ] [ button [ Style.classes.button.cancel, onClick <| cancelMsg ] [ text "Cancel" ] ]
                    ]
                }
        , viewChoiceLine =
            \recipe ->
                let
                    selectMsg =
                        Pages.Util.Choice.Page.SelectChoice <| recipe
                in
                { display =
                    recipeInfo recipe
                        ++ [ { attributes = [ Style.classes.editable, Style.classes.numberCell ]
                             , children = []
                             }
                           ]
                , controls =
                    [ td [ Style.classes.controls ] [ button [ Style.classes.button.select, onClick selectMsg ] [ text "Select" ] ]
                    , td [ Style.classes.controls ] [ NavigationUtil.recipeEditorLinkButton recipe.id ]
                    ]
                }
        }
        main



-- todo: Simplified assumption that the third column should be removed.


recipeInfo : Recipe -> List (HtmlUtil.Column msg)
recipeInfo =
    Pages.Recipes.View.recipeInfoColumns
        >> List.Extra.removeAt 2



-- Todo: The function is oddly specific, and the implementation with the fixed amount of columns is awkward,
-- especially because the non-matching case should never occur.


recipeInfoFromMap : DictList RecipeId (Editing Recipe MealEntryCreationClientInput) -> RecipeId -> List (HtmlUtil.Column msg)
recipeInfoFromMap recipes recipeId =
    DictList.get recipeId recipes
        |> Maybe.Extra.unwrap (List.repeat 4 { attributes = [ Style.classes.editable ], children = [] }) (.original >> recipeInfo)
