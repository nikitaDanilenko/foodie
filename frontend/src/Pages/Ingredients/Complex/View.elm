module Pages.Ingredients.Complex.View exposing (viewComplexIngredients, viewFoods)

import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ScalingMode as ScalingMode exposing (ScalingMode)
import Basics.Extra exposing (flip)
import Dropdown exposing (dropdown)
import Html exposing (Html, button, input, label, td, text, th)
import Html.Attributes exposing (disabled, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Lens
import Pages.Ingredients.Complex.Page as Page
import Pages.Ingredients.ComplexIngredientCreationClientInput as ComplexIngredientCreationClientInput
import Pages.Ingredients.ComplexIngredientUpdateClientInput as ComplexIngredientUpdateClientInput
import Pages.Util.Choice.Page
import Pages.Util.Choice.View
import Pages.Util.DictListUtil as DictListUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.NavigationUtil as NavigationUtil
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput
import Util.DictList as DictList
import Util.Editing as Editing
import Util.MaybeUtil as MaybeUtil
import Util.SearchUtil as SearchUtil


viewComplexIngredients : Page.Main -> Html Page.LogicMsg
viewComplexIngredients main =
    Pages.Util.Choice.View.viewElements
        { nameOfChoice = .name
        , choiceIdOfElement = .complexFoodId
        , idOfElement = .complexFoodId
        , elementHeaderColumns =
            [ th [] [ label [] [ text "Name" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Factor" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Unit" ] ]
            ]
        , info =
            \complexIngredient ->
                let
                    complexFood =
                        DictList.get complexIngredient.complexFoodId main.choices |> Maybe.map .original

                    amountInfo =
                        complexFood
                            |> Maybe.Extra.unwrap "" amountInfoOf

                    editMsg =
                        Pages.Util.Choice.Page.EnterEdit complexIngredient.complexFoodId |> onClick
                in
                { display =
                    [ { attributes = [ Style.classes.editable ], children = [ label [] [ text <| Maybe.Extra.unwrap "" .name <| complexFood ] ] }
                    , { attributes = [ Style.classes.editable, Style.classes.numberLabel ], children = [ label [] [ text <| String.fromFloat <| .factor <| complexIngredient ] ] }
                    , { attributes = [ Style.classes.editable, Style.classes.numberLabel ], children = [ label [] [ text <| scalingModeName amountInfo <| .scalingMode <| complexIngredient ] ] }
                    ]
                , controls =
                    [ td [ Style.classes.controls ] [ button [ Style.classes.button.edit, editMsg ] [ text "Edit" ] ]
                    , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Pages.Util.Choice.Page.RequestDelete complexIngredient.complexFoodId) ] [ text "Delete" ] ]
                    , td [ Style.classes.controls ] [ NavigationUtil.recipeEditorLinkButton complexIngredient.complexFoodId ]
                    , td [ Style.classes.controls ] [ NavigationUtil.complexFoodNutrientLinkButton complexIngredient.complexFoodId ]
                    ]
                }
        , isValidInput = .factor >> ValidatedInput.isValid
        , edit =
            \complexIngredient complexIngredientUpdateClientInput ->
                let
                    complexFood =
                        DictList.get complexIngredient.complexFoodId main.choices |> Maybe.map .original
                in
                [ { attributes = []
                  , children =
                        [ label [] [ text <| Maybe.Extra.unwrap "" .name <| complexFood ] ]
                  }
                , { attributes = [ Style.classes.numberCell ]
                  , children =
                        [ input
                            [ value
                                complexIngredientUpdateClientInput.factor.text
                            , onInput
                                (flip
                                    (ValidatedInput.lift
                                        ComplexIngredientUpdateClientInput.lenses.factor
                                    ).set
                                    complexIngredientUpdateClientInput
                                    >> Pages.Util.Choice.Page.Edit complexIngredient.complexFoodId
                                )
                            , Style.classes.numberLabel
                            ]
                            []
                        ]
                  }
                , { attributes = [ Style.classes.numberLabel ]
                  , children =
                        [ dropdown
                            { items = complexFood |> Maybe.Extra.unwrap [] unitDropdownItems
                            , emptyItem = Nothing
                            , onChange =
                                \unit ->
                                    complexIngredientUpdateClientInput
                                        |> (unit |> Maybe.andThen ScalingMode.fromString |> Maybe.Extra.unwrap identity ComplexIngredientUpdateClientInput.lenses.scalingMode.set)
                                        |> Pages.Util.Choice.Page.Edit complexIngredient.complexFoodId
                            }
                            []
                            (complexIngredient |> .scalingMode |> ScalingMode.toString |> Just)
                        ]
                  }
                ]
        }
        main


viewFoods : Page.Main -> Html Page.LogicMsg
viewFoods main =
    let
        ( factor, unit ) =
            if DictListUtil.existsValue Editing.isUpdate main.choices then
                ( "Factor", "Unit" )

            else
                ( "", "" )
    in
    Pages.Util.Choice.View.viewChoices
        { matchesSearchText = \string -> .name >> SearchUtil.search string
        , sortBy = .name
        , choiceHeaderColumns =
            [ th [] [ label [] [ text "Name" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text factor ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text unit ] ]
            ]
        , idOfChoice = .recipeId
        , elementCreationLine =
            \complexFood creation ->
                let
                    validInput =
                        creation.factor |> ValidatedInput.isValid

                    addMsg =
                        Pages.Util.Choice.Page.Create complexFood.recipeId

                    cancelMsg =
                        Pages.Util.Choice.Page.DeselectChoice complexFood.recipeId
                in
                { display =
                    [ { attributes = [ Style.classes.editable ]
                      , children = [ label [] [ text <| .name <| complexFood ] ]
                      }
                    , { attributes = [ Style.classes.numberCell ]
                      , children =
                            [ input
                                ([ MaybeUtil.defined <| value creation.factor.text
                                 , MaybeUtil.defined <|
                                    onInput
                                        (flip
                                            (ValidatedInput.lift
                                                ComplexIngredientCreationClientInput.lenses.factor
                                            ).set
                                            creation
                                            >> Pages.Util.Choice.Page.UpdateCreation
                                        )
                                 , MaybeUtil.defined <| Style.classes.numberLabel
                                 , MaybeUtil.defined <| HtmlUtil.onEscape <| cancelMsg
                                 , MaybeUtil.optional validInput <| onEnter <| addMsg
                                 ]
                                    |> Maybe.Extra.values
                                )
                                []
                            ]
                      }
                    , { attributes = [ Style.classes.editable, Style.classes.numberLabel ]
                      , children =
                            [ dropdown
                                { items = complexFood |> unitDropdownItems
                                , emptyItem = Nothing
                                , onChange =
                                    \u ->
                                        creation
                                            |> (u |> Maybe.andThen ScalingMode.fromString |> Maybe.Extra.unwrap identity ComplexIngredientCreationClientInput.lenses.scalingMode.set)
                                            |> Pages.Util.Choice.Page.UpdateCreation
                                }
                                []
                                (creation |> .scalingMode |> ScalingMode.toString |> Just)
                            ]
                      }
                    ]
                , controls =
                    [ td [ Style.classes.controls ]
                        [ button
                            ([ MaybeUtil.defined <| Style.classes.button.confirm
                             , MaybeUtil.defined <| disabled <| not <| validInput
                             , MaybeUtil.optional validInput <| onClick <| addMsg
                             ]
                                |> Maybe.Extra.values
                            )
                            [ text "Add"
                            ]
                        ]
                    , td [ Style.classes.controls ]
                        [ button [ Style.classes.button.cancel, onClick <| cancelMsg ]
                            [ text "Cancel" ]
                        ]
                    ]
                }
        , viewChoiceLine =
            \complexFood ->
                let
                    exists =
                        DictListUtil.existsValue (\complexIngredient -> complexIngredient.original.complexFoodId == complexFood.recipeId) main.elements

                    ( selectName, selectStyles ) =
                        if exists then
                            ( "Added", [ Style.classes.button.edit, disabled True ] )

                        else
                            ( "Select", [ Style.classes.button.confirm, onClick <| Pages.Util.Choice.Page.SelectChoice <| complexFood ] )
                in
                { display =
                    [ { attributes = [ Style.classes.editable ]
                      , children = [ label [] [ text <| .name <| complexFood ] ]
                      }
                    , { attributes = [ Style.classes.editable, Style.classes.numberCell ]
                      , children = []
                      }
                    , { attributes = [ Style.classes.editable, Style.classes.numberCell ]
                      , children = []
                      }
                    ]
                , controls =
                    [ td [ Style.classes.controls ] [ button selectStyles [ text <| selectName ] ]
                    , td [ Style.classes.controls ] [ NavigationUtil.recipeEditorLinkButton complexFood.recipeId ]
                    , td [ Style.classes.controls ] [ NavigationUtil.recipeNutrientsLinkButton complexFood.recipeId ]
                    ]
                }
        }
        main


amountInfoOf : ComplexFood -> String
amountInfoOf complexFood =
    String.concat
        [ complexFood.amountGrams |> String.fromFloat
        , "g"
        , Maybe.Extra.unwrap ""
            (\amountMillilitres -> String.concat [ " = ", amountMillilitres |> String.fromFloat, "ml" ])
            complexFood.amountMilliLitres
        ]


unitDropdownItems : ComplexFood -> List Dropdown.Item
unitDropdownItems complexFood =
    let
        volumeMode =
            complexFood.amountMilliLitres |> Maybe.Extra.unwrap [] (always [ ScalingMode.Volume ])

        scalingModes =
            [ ScalingMode.Recipe
            , ScalingMode.Weight
            ]
                ++ volumeMode

        amountInfo =
            amountInfoOf complexFood
    in
    scalingModes
        |> List.map (\scalingMode -> scalingModeName amountInfo scalingMode |> flip unitDropdownItem scalingMode)


unitDropdownItem : String -> ScalingMode -> Dropdown.Item
unitDropdownItem sizeText scalingMode =
    { value = scalingMode |> ScalingMode.toString
    , text = sizeText
    , enabled = True
    }


scalingModeName : String -> ScalingMode -> String
scalingModeName fullSize scalingMode =
    case scalingMode of
        ScalingMode.Recipe ->
            "Full recipe (" ++ fullSize ++ ")"

        ScalingMode.Weight ->
            "100g"

        ScalingMode.Volume ->
            "100ml"
