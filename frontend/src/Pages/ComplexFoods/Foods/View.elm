module Pages.ComplexFoods.Foods.View exposing (..)

import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Html exposing (Attribute, Html, button, input, label, td, text, th)
import Html.Attributes exposing (disabled, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.ComplexFoods.ComplexFoodCreationClientInput as ComplexFoodCreationClientInput
import Pages.ComplexFoods.ComplexFoodUpdateClientInput as ComplexFoodUpdateClientInput
import Pages.ComplexFoods.Foods.Page as Page
import Pages.Recipes.View
import Pages.Util.Choice.Page
import Pages.Util.Choice.View
import Pages.Util.DictListUtil as DictListUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.NavigationUtil as NavigationUtil
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)
import Util.Editing as Editing
import Util.MaybeUtil as MaybeUtil
import Util.SearchUtil as SearchUtil


viewComplexFoods : Page.Main -> Html Page.LogicMsg
viewComplexFoods main =
    Pages.Util.Choice.View.viewElements
        { nameOfChoice = .name
        , choiceIdOfElement = .recipeId
        , idOfElement = .recipeId
        , elementHeaderColumns =
            [ th [] [ label [] [ text "Name" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Amount in g" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Amount in ml" ] ]
            ]
        , info =
            \complexFood ->
                { display =
                    [ { attributes = [ Style.classes.editable ]
                      , children = [ label [] [ text <| .name <| complexFood ] ]
                      }
                    , { attributes = [ Style.classes.editable, Style.classes.numberLabel ]
                      , children = [ label [] [ text <| String.fromFloat <| complexFood.amountGrams ] ]
                      }
                    , { attributes = [ Style.classes.editable, Style.classes.numberLabel ]
                      , children = [ label [] [ text <| Maybe.Extra.unwrap "" String.fromFloat <| complexFood.amountMilliLitres ] ]
                      }
                    ]
                , controls =
                    [ td [ Style.classes.controls ] [ button [ Style.classes.button.edit, onClick <| Pages.Util.Choice.Page.EnterEdit <| complexFood.recipeId ] [ text "Edit" ] ]
                    , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick <| Pages.Util.Choice.Page.RequestDelete <| complexFood.recipeId ] [ text "Delete" ] ]
                    , td [ Style.classes.controls ] [ NavigationUtil.recipeEditorLinkButton complexFood.recipeId ]
                    , td [ Style.classes.controls ] [ NavigationUtil.recipeNutrientsLinkButton complexFood.recipeId ]
                    ]
                }
        , isValidInput =
            \complexFoodUpdateClientInput ->
                List.all identity
                    [ complexFoodUpdateClientInput.amountGrams |> ValidatedInput.isValid
                    , complexFoodUpdateClientInput.amountMilliLitres |> ValidatedInput.isValid
                    ]
        , edit =
            \complexFood complexFoodUpdateClientInput ->
                [ { attributes = []
                  , children = [ label [] [ text <| .name <| complexFood ] ]
                  }
                , { attributes = [ Style.classes.numberCell ]
                  , children =
                        [ input
                            [ value <| complexFoodUpdateClientInput.amountGrams.text
                            , onInput
                                (flip
                                    (ValidatedInput.lift
                                        ComplexFoodUpdateClientInput.lenses.amountGrams
                                    ).set
                                    complexFoodUpdateClientInput
                                    >> Pages.Util.Choice.Page.Edit complexFood.recipeId
                                )
                            , Style.classes.numberLabel
                            ]
                            []
                        ]
                  }
                , { attributes = [ Style.classes.numberCell ]
                  , children =
                        [ input
                            [ value <| complexFoodUpdateClientInput.amountMilliLitres.text
                            , onInput <|
                                flip
                                    (ValidatedInput.lift
                                        ComplexFoodUpdateClientInput.lenses.amountMilliLitres
                                    ).set
                                    complexFoodUpdateClientInput
                                    >> Pages.Util.Choice.Page.Edit complexFood.recipeId
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
        anySelection =
            main.choices
                |> DictListUtil.existsValue Editing.isUpdate

        ( amountGrams, amountMillilitres ) =
            if anySelection then
                ( "Amount in g", "Amount in ml" )

            else
                ( "", "" )
    in
    Pages.Util.Choice.View.viewChoices
        { matchesSearchText = \string recipe -> SearchUtil.search string recipe.name || SearchUtil.search string (recipe.description |> Maybe.withDefault "")
        , sortBy = .name
        , choiceHeaderColumns =
            [ th [] [ label [] [ text "Name" ] ]
            , th [] [ label [] [ text "Description" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Servings" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Serving size" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text amountGrams ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text amountMillilitres ] ]
            ]
        , idOfChoice = .id
        , elementCreationLine =
            \recipe complexFoodClientInput ->
                let
                    createMsg =
                        Pages.Util.Choice.Page.Create recipe.id

                    cancelMsg =
                        Pages.Util.Choice.Page.DeselectChoice recipe.id

                    validInput =
                        List.all identity
                            [ complexFoodClientInput.amountGrams |> ValidatedInput.isValid
                            , complexFoodClientInput.amountMilliLitres |> ValidatedInput.isValid
                            ]

                    inputCells =
                        [ { attributes = [ Style.classes.numberCell ]
                          , children =
                                [ input
                                    ([ MaybeUtil.defined <| value complexFoodClientInput.amountGrams.text
                                     , MaybeUtil.defined <|
                                        onInput <|
                                            flip
                                                (ValidatedInput.lift
                                                    ComplexFoodCreationClientInput.lenses.amountGrams
                                                ).set
                                                complexFoodClientInput
                                                >> Pages.Util.Choice.Page.UpdateCreation
                                     , MaybeUtil.defined <| Style.classes.numberLabel
                                     , MaybeUtil.defined <| HtmlUtil.onEscape cancelMsg
                                     , MaybeUtil.optional validInput <| onEnter createMsg
                                     ]
                                        |> Maybe.Extra.values
                                    )
                                    []
                                ]
                          }
                        , { attributes = [ Style.classes.numberCell ]
                          , children =
                                [ input
                                    ([ MaybeUtil.defined <| value complexFoodClientInput.amountMilliLitres.text
                                     , MaybeUtil.defined <|
                                        onInput <|
                                            flip
                                                (ValidatedInput.lift
                                                    ComplexFoodCreationClientInput.lenses.amountMilliLitres
                                                ).set
                                                complexFoodClientInput
                                                >> Pages.Util.Choice.Page.UpdateCreation
                                     , MaybeUtil.defined <| Style.classes.numberLabel
                                     , MaybeUtil.defined <| HtmlUtil.onEscape cancelMsg
                                     , MaybeUtil.optional validInput <| onEnter createMsg
                                     ]
                                        |> Maybe.Extra.values
                                    )
                                    []
                                ]
                          }
                        ]
                in
                { display = Pages.Recipes.View.recipeInfoColumns recipe ++ inputCells
                , controls =
                    [ td [ Style.classes.controls ]
                        [ button
                            ([ MaybeUtil.defined <| Style.classes.button.confirm
                             , MaybeUtil.defined <| disabled <| not <| validInput
                             , MaybeUtil.optional validInput <| onClick createMsg
                             ]
                                |> Maybe.Extra.values
                            )
                            [ text <| "Add"
                            ]
                        ]
                    , td [ Style.classes.controls ]
                        [ button [ Style.classes.button.cancel, onClick cancelMsg ] [ text "Cancel" ] ]
                    ]
                }
        , viewChoiceLine =
            \recipe ->
                let
                    exists =
                        DictListUtil.existsValue (\complexFood -> complexFood.original.recipeId == recipe.id) main.elements

                    ( buttonText, buttonAttributes ) =
                        if exists then
                            ( "Added", [ Style.classes.button.edit, disabled <| True ] )

                        else
                            ( "Select", [ Style.classes.button.select, onClick <| Pages.Util.Choice.Page.SelectChoice <| recipe ] )
                in
                { display =
                    Pages.Recipes.View.recipeInfoColumns recipe
                        ++ [ { attributes = []
                             , children = []
                             }
                           , { attributes = []
                             , children = []
                             }
                           ]
                , controls =
                    [ td [ Style.classes.controls ] [ button buttonAttributes [ text <| buttonText ] ]
                    , td [ Style.classes.controls ] [ NavigationUtil.recipeEditorLinkButton recipe.id ]
                    , td [ Style.classes.controls ] [ NavigationUtil.recipeNutrientsLinkButton recipe.id ]
                    ]
                }
        }
        main
