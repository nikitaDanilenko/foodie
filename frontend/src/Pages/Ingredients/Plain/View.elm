module Pages.Ingredients.Plain.View exposing (viewFoods, viewIngredients)

import Addresses.Frontend
import Api.Auxiliary exposing (ComplexFoodId, FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.Food exposing (Food)
import Api.Types.Ingredient exposing (Ingredient)
import Api.Types.Measure exposing (Measure)
import Basics.Extra exposing (flip)
import Dropdown exposing (Item, dropdown)
import Html exposing (Attribute, Html, button, input, label, td, text, th)
import Html.Attributes exposing (disabled, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import List.Extra
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Ingredients.AmountUnitClientInput as AmountUnitClientInput
import Pages.Ingredients.IngredientCreationClientInput as IngredientCreationClientInput
import Pages.Ingredients.IngredientUpdateClientInput as IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.Ingredients.Plain.Page as Page
import Pages.Util.Choice.Page
import Pages.Util.Choice.View
import Pages.Util.DictListUtil as DictListUtil
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Links as Links
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput
import Util.DictList as DictList exposing (DictList)
import Util.Editing as Editing exposing (Editing)
import Util.MaybeUtil as MaybeUtil
import Util.SearchUtil as SearchUtil


viewIngredients : Page.Main -> Html Page.LogicMsg
viewIngredients main =
    let
        unitDropdown foodId =
            main.choices
                |> DictList.get foodId
                |> Maybe.Extra.unwrap [] (.original >> .measures)
                |> List.map startingDropdownUnit
    in
    Pages.Util.Choice.View.viewElements
        { nameOfChoice = .name
        , choiceIdOfElement = .foodId
        , idOfElement = .id
        , elementHeaderColumns =
            [ th [] [ label [] [ text "Name" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Amount" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text "Unit" ] ]
            ]
        , info =
            \ingredient ->
                let
                    food =
                        DictList.get ingredient.foodId main.choices |> Maybe.map .original
                in
                { display =
                    [ { attributes = [ Style.classes.editable ]
                      , children = [ label [] [ text <| Maybe.Extra.unwrap "" .name <| food ] ]
                      }
                    , { attributes = [ Style.classes.editable, Style.classes.numberLabel ]
                      , children = [ label [] [ text <| String.fromFloat <| ingredient.amountUnit.factor ] ]
                      }
                    , { attributes = [ Style.classes.editable, Style.classes.numberLabel ]
                      , children =
                            [ label []
                                [ text <|
                                    Maybe.Extra.unwrap "" .name <|
                                        Maybe.andThen (measureOfFood ingredient.amountUnit.measureId) <|
                                            food
                                ]
                            ]
                      }
                    ]
                , controls =
                    [ td [ Style.classes.controls ]
                        [ button [ Style.classes.button.edit, onClick <| Pages.Util.Choice.Page.EnterEdit <| ingredient.id ] [ text "Edit" ] ]
                    , td [ Style.classes.controls ]
                        [ button [ Style.classes.button.delete, onClick <| Pages.Util.Choice.Page.RequestDelete <| ingredient.id ] [ text "Delete" ] ]
                    , td [ Style.classes.controls ]
                        [ Links.linkButton
                            { url = Links.frontendPage <| Addresses.Frontend.statisticsFoodSelect.address <| ingredient.foodId
                            , attributes = [ Style.classes.button.nutrients ]
                            , children = [ text "Nutrients" ]
                            }
                        ]
                    ]
                }
        , isValidInput = .amountUnit >> .factor >> ValidatedInput.isValid
        , edit =
            \ingredient ingredientUpdateClientInput ->
                let
                    food =
                        DictList.get ingredient.foodId main.choices |> Maybe.map .original

                    maybeMeasure =
                        food
                            |> Maybe.andThen
                                (measureOfFood ingredient.amountUnit.measureId)
                in
                [ { attributes = []
                  , children = [ label [] [ text <| Maybe.Extra.unwrap "" .name <| food ] ]
                  }
                , { attributes = [ Style.classes.numberCell ]
                  , children =
                        [ input
                            [ value <|
                                ingredientUpdateClientInput.amountUnit.factor.text
                            , onInput <|
                                flip
                                    (ValidatedInput.lift
                                        (IngredientUpdateClientInput.lenses.amountUnit
                                            |> Compose.lensWithLens AmountUnitClientInput.lenses.factor
                                        )
                                    ).set
                                    ingredientUpdateClientInput
                                    >> Pages.Util.Choice.Page.Edit ingredient.id
                            , Style.classes.numberLabel
                            ]
                            []
                        ]
                  }
                , { attributes = [ Style.classes.numberCell ]
                  , children =
                        [ dropdown
                            { items = unitDropdown ingredient.foodId
                            , emptyItem = Maybe.map startingDropdownUnit <| maybeMeasure
                            , onChange =
                                onChangeDropdown
                                    { amountUnitLens = IngredientUpdateClientInput.lenses.amountUnit
                                    , measureIdOf = .amountUnit >> .measureId
                                    , mkMsg = Pages.Util.Choice.Page.Edit ingredient.id
                                    , input = ingredientUpdateClientInput
                                    }
                            }
                            [ Style.classes.numberLabel ]
                            (maybeMeasure
                                |> Maybe.map .name
                            )
                        ]
                  }
                ]
        }
        main


viewFoods : Page.Main -> Html Page.LogicMsg
viewFoods main =
    let
        ( amount, unit ) =
            if DictListUtil.existsValue Editing.isUpdate main.choices then
                ( "Amount", "Unit" )

            else
                ( "", "" )
    in
    Pages.Util.Choice.View.viewChoices
        { matchesSearchText = \string -> .name >> SearchUtil.search string
        , sortBy = .name
        , choiceHeaderColumns =
            [ th [] [ label [] [ text "Name" ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text amount ] ]
            , th [ Style.classes.numberLabel ] [ label [] [ text unit ] ]
            ]
        , idOfChoice = .id
        , elementCreationLine =
            \food creation ->
                let
                    addMsg =
                        Pages.Util.Choice.Page.Create food.id

                    cancelMsg =
                        Pages.Util.Choice.Page.DeselectChoice food.id

                    ( confirmName, confirmStyle ) =
                        if DictListUtil.existsValue (\ingredient -> ingredient.original.foodId == creation.foodId) main.elements then
                            ( "Add again", Style.classes.button.edit )

                        else
                            ( "Add"
                            , Style.classes.button.confirm
                            )

                    validInput =
                        creation.amountUnit.factor |> ValidatedInput.isValid
                in
                { display =
                    [ { attributes = [ Style.classes.editable ]
                      , children = [ label [] [ text <| .name <| food ] ]
                      }
                    , { attributes = [ Style.classes.numberCell ]
                      , children =
                            [ input
                                ([ MaybeUtil.defined <| value creation.amountUnit.factor.text
                                 , MaybeUtil.defined <|
                                    onInput <|
                                        flip
                                            (ValidatedInput.lift
                                                (IngredientCreationClientInput.amountUnit
                                                    |> Compose.lensWithLens AmountUnitClientInput.lenses.factor
                                                )
                                            ).set
                                            creation
                                            >> Pages.Util.Choice.Page.UpdateCreation
                                 , MaybeUtil.defined <| Style.classes.numberLabel
                                 , MaybeUtil.defined <| HtmlUtil.onEscape cancelMsg
                                 , MaybeUtil.optional validInput <| onEnter addMsg
                                 ]
                                    |> Maybe.Extra.values
                                )
                                []
                            ]
                      }
                    , { attributes = [ Style.classes.numberCell ]
                      , children =
                            [ dropdown
                                { items =
                                    food.measures
                                        |> List.map startingDropdownUnit
                                , emptyItem = Nothing
                                , onChange =
                                    onChangeDropdown
                                        { amountUnitLens = IngredientCreationClientInput.amountUnit
                                        , measureIdOf = .amountUnit >> .measureId
                                        , mkMsg = Pages.Util.Choice.Page.UpdateCreation
                                        , input = creation
                                        }
                                }
                                [ Style.classes.numberLabel
                                , HtmlUtil.onEscape cancelMsg
                                ]
                                (creation.amountUnit.measureId |> String.fromInt |> Just)
                            ]
                      }
                    ]
                , controls =
                    [ td [ Style.classes.controls ]
                        [ button
                            [ confirmStyle
                            , disabled <| not <| validInput
                            , onClick <| addMsg
                            ]
                            [ text confirmName
                            ]
                        ]
                    , td [ Style.classes.controls ]
                        [ button [ Style.classes.button.cancel, onClick <| cancelMsg ] [ text "Cancel" ] ]
                    ]
                }
        , viewChoiceLine =
            \food ->
                { display =
                    [ { attributes = [ Style.classes.editable ]
                      , children = [ label [] [ text <| .name <| food ] ]
                      }
                    , { attributes = [ Style.classes.editable, Style.classes.numberCell ]
                      , children = []
                      }
                    , { attributes = [ Style.classes.editable, Style.classes.numberCell ]
                      , children = []
                      }
                    ]
                , controls =
                    [ td [ Style.classes.controls ] [ button [ Style.classes.button.select, onClick <| Pages.Util.Choice.Page.SelectChoice <| food ] [ text "Select" ] ]
                    , td [ Style.classes.controls ]
                        [ Links.linkButton
                            { url = Links.frontendPage <| Addresses.Frontend.statisticsFoodSelect.address <| food.id
                            , attributes = [ Style.classes.button.nutrients ]
                            , children = [ text "Nutrients" ]
                            }
                        ]
                    ]
                }
        }
        main


measureOfFood : MeasureId -> Food -> Maybe Measure
measureOfFood measureId food =
    food
        |> .measures
        |> List.Extra.find (\measure -> measure.id == measureId)


startingDropdownUnit : Measure -> Dropdown.Item
startingDropdownUnit measure =
    { value = String.fromInt measure.id
    , text = measure.name
    , enabled = True
    }


onChangeDropdown :
    { amountUnitLens : Lens input AmountUnitClientInput.AmountUnitClientInput
    , measureIdOf : input -> MeasureId
    , input : input
    , mkMsg : input -> Page.LogicMsg
    }
    -> Maybe String
    -> Page.LogicMsg
onChangeDropdown ps =
    Maybe.andThen String.toInt
        >> Maybe.withDefault (ps.measureIdOf ps.input)
        >> flip (ps.amountUnitLens |> Compose.lensWithLens AmountUnitClientInput.lenses.measureId).set ps.input
        >> ps.mkMsg
