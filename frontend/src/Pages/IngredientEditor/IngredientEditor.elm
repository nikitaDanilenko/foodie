module Pages.InIngredientEditor.IngredientEditor exposing (Flags, Model, Msg, init, update, updateFoods, updateJWT, view)

import Api.Auxiliary exposing (FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Lenses.IngredientUpdateLens as IngredientUpdateLens
import Api.Types.Food exposing (Food, decoderFood)
import Api.Types.Ingredient exposing (Ingredient, decoderIngredient)
import Api.Types.IngredientUpdate exposing (IngredientUpdate)
import Api.Types.Measure exposing (Measure)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Dict exposing (Dict)
import Dropdown exposing (dropdown)
import Either exposing (Either)
import Html exposing (Html, button, div, input, label, td, text, thead, tr)
import Html.Attributes exposing (class, id, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Http exposing (Error)
import Json.Decode as Decode
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.IngredientEditor.AmountUnitClientInput as AmountUnitClientInput
import Pages.IngredientEditor.IngredientUpdateClientInput as IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.IngredientEditor.NamedIngredient as NamedIngredient exposing (NamedIngredient)
import Pages.Util.ValidatedInput as ValidatedInput
import Ports exposing (doFetchToken)
import Util.Editing exposing (Editing)
import Util.HttpUtil as HttpUtil


type alias Model =
    { configuration : Configuration
    , jwt : String
    , recipeId : RecipeId
    , ingredients : List (Either NamedIngredient (Editing NamedIngredient IngredientUpdateClientInput))
    , foods : FoodMap
    , measures : MeasureMap
    , foodsSearchString : String
    }


type alias FoodMap =
    Dict FoodId Food


type alias MeasureMap =
    Dict MeasureId Measure


jwtLens : Lens Model JWT
jwtLens =
    Lens .jwt (\b a -> { a | jwt = b })


foodsLens : Lens Model FoodMap
foodsLens =
    Lens .foods (\b a -> { a | foods = b })


ingredientsLens : Lens Model (List (Either NamedIngredient (Editing NamedIngredient IngredientUpdateClientInput)))
ingredientsLens =
    Lens .ingredients (\b a -> { a | ingredients = b })


foodsSearchStringLens : Lens Model String
foodsSearchStringLens =
    Lens .foodsSearchString (\b a -> { a | foodsSearchString = b })


type Msg
    = AddIngredient
    | GotAddIngredientResponse (Result Error Ingredient)
    | UpdateIngredient IngredientId IngredientUpdateClientInput
    | SaveIngredientEdit IngredientId
    | GotSaveIngredientResponse IngredientId (Result Error Ingredient)
    | EnterEditIngredient IngredientId
    | ExitEditIngredientAt IngredientId
    | DeleteIngredient IngredientId
    | GotDeleteIngredientResponse IngredientId (Result Error ())
    | GotFetchIngredientsResponse (Result Error (List Ingredient))
    | GotFetchFoodsResponse (Result Error (List Food))
    | UpdateJWT String
    | UpdateFoods String
    | SetFoodsSearchString String


updateJWT : String -> Msg
updateJWT =
    UpdateJWT


updateFoods : String -> Msg
updateFoods =
    UpdateFoods


type alias Flags =
    { configuration : Configuration
    , jwt : Maybe String
    , recipeId : RecipeId
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( jwt, cmd ) =
            case flags.jwt of
                Just jwt ->
                    ( jwt
                    , fetchIngredients
                        { configuration = flags.configuration
                        , jwt = jwt
                        , recipeId = flags.recipeId
                        }
                    )

                Nothing ->
                    ( "", doFetchToken () )
    in
    ( { configuration = flags.configuration
      , jwt = jwt
      , recipeId = flags.recipeId
      , ingredients = []
      , foods = Dict.empty
      , measures = Dict.empty
      , foodsSearchString = ""
      }
    , cmd
    )


view : Model -> Html Msg
view model =
    let
        viewEditIngredients =
            List.map
                (Either.unpack
                    (editOrDeleteIngredientLine model.foods)
                    (\e -> e.update |> editIngredientLine model.measures model.foods e.original)
                )
    in
    div [ id "editor" ]
        [ div [ id "ingredientsView" ]
            [ thead []
                [ tr []
                    [ td [] [ label [] [ text "Name" ] ]
                    , td [] [ label [] [ text "Amount" ] ]
                    , td [] [ label [] [ text "Unit" ] ]
                    ]
                ]
                :: viewEditIngredients model.ingredients
            ]
        , div [ id "addIngredientView" ]
            (div [ id "addIngredient" ]
                [ div [ id "searchField" ]
                    [ label [] [ text (special 128269) ]
                    , input [ onInput SetFoodsSearchString ] []
                    ]
                ]
                :: thead []
                    [ tr []
                        [ td [] [ label [] [ text "Name" ] ]
                        , td [] [ label [] [ text "Amount" ] ]
                        , td [] [ label [] [ text "Unit" ] ]
                        ]
                    ]
                :: viewFoods model.foodsSearchString
            )
        ]


editOrDeleteIngredientLine : FoodMap -> NamedIngredient -> Html Msg
editOrDeleteIngredientLine foodMap namedIngredient =
    tr [ id "editingIngredient" ]
        [ td [] [ label [] [ text namedIngredient.name ] ]
        , td [] [ label [] [ namedIngredient.ingredient.amountUnit.factor |> String.fromFloat |> text ] ]
        , td [] [ label [] [ namedIngredient.ingredient.amountUnit.measureId |> flip Dict.get foodMap |> Maybe.Extra.unpack (always "") .foodName |> text ] ]
        , td [] [ button [ class "button", onClick (EnterEditIngredient namedIngredient.ingredient.id) ] [ text "Edit" ] ]
        , td [] [ button [ class "button", onClick (DeleteIngredient namedIngredient.ingredient.id) ] [ text "Delete" ] ]
        ]


editIngredientLine : MeasureMap -> FoodMap -> NamedIngredient -> IngredientUpdateClientInput -> Html Msg
editIngredientLine measureMap foodMap namedIngredient ingredientUpdateClientInput =
    let
        saveOnEnter =
            onEnter (SaveIngredientEdit namedIngredient.ingredient.id)
    in
    -- todo: Check whether the update behaviour is correct. There is the implicit assumption that the update originates from the ingredient.
    --       cf. name, description
    div [ class "ingredientLine" ]
        [ div [ class "name" ]
            [ label [] [ text "Name" ]
            , label []
                [ text namedIngredient.name ]
            ]
        , [ div [ class "amount" ]
                [ label [] [ text "Amount" ]
                , input
                    [ ingredientUpdateClientInput.amountUnit.factor.text |> value
                    , onInput
                        (flip
                            (ValidatedInput.lift
                                (IngredientUpdateClientInput.amountUnit
                                    |> Compose.lensWithLens AmountUnitClientInput.factor
                                )
                            ).set
                            ingredientUpdateClientInput
                            >> UpdateIngredient namedIngredient.ingredient.id
                        )
                    , saveOnEnter
                    ]
                    []
                ]
          , div [ class "unit" ]
                [ label [] [ text "Unit" ]
                , div [ class "unit" ]
                    [ dropdown
                        { items =
                            foodMap
                                |> Dict.get namedIngredient.ingredient.foodId
                                |> Maybe.Extra.unpack (\_ -> []) .measures
                        , emptyItem =
                            Just
                                { value = namedIngredient.ingredient.amountUnit.measureId
                                , text =
                                    measureMap
                                        |> Dict.get namedIngredient.ingredient.amountUnit.measureId
                                        |> Maybe.Extra.unpack (\_ -> "") .name
                                , enabled = True
                                }
                        , onChange =
                            Maybe.withDefault ingredientUpdateClientInput.amountUnit.measureId
                                >> flip (IngredientUpdateClientInput.amountUnit |> Compose.lensWithLens AmountUnitClientInput.measureId).set ingredientUpdateClientInput
                                >> UpdateIngredient namedIngredient.ingredient.id
                        }
                        []
                        (Just namedIngredient.ingredient.amountUnit.measureId)
                    ]
                ]
          , button [ class "button", onClick (SaveIngredientEdit namedIngredient.ingredient.id) ]
                [ text "Save" ]
          , button [ class "button", onClick (ExitEditIngredientAt namedIngredient.ingredient.id) ]
                [ text "Cancel" ]
          ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddIngredient ->
            ( model, Cmd.none )

        GotAddIngredientResponse result ->
            ( model, Cmd.none )

        UpdateIngredient ingredientId ingredientUpdate ->
            ( model, Cmd.none )

        SaveIngredientEdit ingredientId ->
            ( model, Cmd.none )

        GotSaveIngredientResponse ingredientId result ->
            ( model, Cmd.none )

        EnterEditIngredient ingredientId ->
            ( model, Cmd.none )

        ExitEditIngredientAt ingredientId ->
            ( model, Cmd.none )

        DeleteIngredient ingredientId ->
            ( model, Cmd.none )

        GotDeleteIngredientResponse ingredientId result ->
            ( model, Cmd.none )

        GotFetchIngredientsResponse result ->
            ( model, Cmd.none )

        GotFetchFoodsResponse result ->
            ( model, Cmd.none )

        UpdateJWT jwt ->
            ( jwtLens.set jwt model
            , fetchIngredients
                { configuration = model.configuration
                , jwt = jwt
                , recipeId = model.recipeId
                }
            )

        UpdateFoods string ->
            case Decode.decodeString (Decode.list decoderFood) string of
                Ok foods ->
                    ( foodsLens.set foods model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        SetFoodsSearchString string ->
            ( foodsSearchStringLens.set string model, Cmd.none )


fetchIngredients : { configuration : Configuration, jwt : JWT, recipeId : RecipeId } -> Cmd Msg
fetchIngredients ps =
    HttpUtil.getJsonWithJWT ps.jwt
        { url = String.join "/" [ ps.configuration.backendURL, "recipe", ps.recipeId, "ingredients" ]
        , expect = HttpUtil.expectJson GotFetchIngredientsResponse (Decode.list decoderIngredient)
        }


special : Int -> String
special =
    Char.fromCode >> String.fromChar
