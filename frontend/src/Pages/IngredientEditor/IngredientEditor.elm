module Pages.IngredientEditor.IngredientEditor exposing (Flags, Model, Msg, init, update, updateFoods, updateJWT, view)

import Api.Auxiliary exposing (FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Lenses.IngredientUpdateLens as IngredientUpdateLens
import Api.Types.Food exposing (Food, decoderFood, encoderFood)
import Api.Types.Ingredient exposing (Ingredient, decoderIngredient)
import Api.Types.IngredientCreation exposing (IngredientCreation, encoderIngredientCreation)
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
import Json.Encode as Encode
import List.Extra
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Monocle.Optional as Optional
import Pages.IngredientEditor.AmountUnitClientInput as AmountUnitClientInput
import Pages.IngredientEditor.IngredientCreationClientInput as IngredientCreationClientInput exposing (IngredientCreationClientInput)
import Pages.IngredientEditor.IngredientUpdateClientInput as IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.IngredientEditor.NamedIngredient as NamedIngredient exposing (NamedIngredient)
import Pages.Util.ValidatedInput as ValidatedInput
import Ports exposing (doFetchFoods, doFetchToken, storeFoods)
import Util.Editing exposing (Editing)
import Util.HttpUtil as HttpUtil
import Util.LensUtil as LensUtil


type alias Model =
    { configuration : Configuration
    , jwt : String
    , recipeId : RecipeId
    , ingredients : List (Either NamedIngredient (Editing NamedIngredient IngredientUpdateClientInput))
    , foods : FoodMap
    , measures : MeasureMap
    , foodsSearchString : String
    , foodsToAdd : List IngredientCreationClientInput
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


foodsToAdd : Lens Model (List IngredientCreationClientInput)
foodsToAdd =
    Lens .foodsToAdd (\b a -> { a | foodsToAdd = b })


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
    | SelectFood Food
    | DeselectFood FoodId
    | AddFood FoodId
    | UpdateAddFood IngredientCreationClientInput
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
                Just token ->
                    ( token
                    , Cmd.batch
                        [ fetchIngredients
                            { configuration = flags.configuration
                            , jwt = token
                            , recipeId = flags.recipeId
                            }

                        -- todo: Check if foods are already present to avoid unnecessary loading.
                        , doFetchFoods ()
                        ]
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
      , foodsToAdd = []
      }
    , cmd
    )


view : Model -> Html Msg
view model =
    let
        viewEditIngredients =
            List.map
                (Either.unpack
                    (editOrDeleteIngredientLine model.measures)
                    (\e -> e.update |> editIngredientLine model.measures model.foods e.original)
                )

        viewFoods searchString =
            model.foods
                |> Dict.filter (\_ v -> String.contains (String.toLower searchString) (String.toLower v.name))
                |> Dict.values
                |> List.sortBy .name
                |> List.map (viewFoodLine model.foods model.measures model.foodsToAdd)
    in
    div [ id "editor" ]
        [ div [ id "ingredientsView" ]
            (thead []
                [ tr []
                    [ td [] [ label [] [ text "Name" ] ]
                    , td [] [ label [] [ text "Amount" ] ]
                    , td [] [ label [] [ text "Unit" ] ]
                    ]
                ]
                :: viewEditIngredients model.ingredients
            )
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


editOrDeleteIngredientLine : MeasureMap -> NamedIngredient -> Html Msg
editOrDeleteIngredientLine measureMap namedIngredient =
    tr [ id "editingIngredient" ]
        [ td [] [ label [] [ text namedIngredient.name ] ]
        , td [] [ label [] [ namedIngredient.ingredient.amountUnit.factor |> String.fromFloat |> text ] ]
        , td [] [ label [] [ namedIngredient.ingredient.amountUnit.measureId |> flip Dict.get measureMap |> Maybe.Extra.unpack (always "") .name |> text ] ]
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
            , label [] [ text namedIngredient.name ]
            ]
        , div [ class "amount" ]
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
                            |> List.map (\m -> { value = String.fromInt m.id, text = m.name, enabled = True })
                    , emptyItem =
                        Just
                            { value = String.fromInt namedIngredient.ingredient.amountUnit.measureId
                            , text =
                                measureMap
                                    |> Dict.get namedIngredient.ingredient.amountUnit.measureId
                                    |> Maybe.Extra.unpack (\_ -> "") .name
                            , enabled = True
                            }
                    , onChange =
                        Maybe.andThen String.toInt
                            >> Maybe.withDefault ingredientUpdateClientInput.amountUnit.measureId
                            >> flip (IngredientUpdateClientInput.amountUnit |> Compose.lensWithLens AmountUnitClientInput.measureId).set ingredientUpdateClientInput
                            >> UpdateIngredient namedIngredient.ingredient.id
                    }
                    []
                    (namedIngredient.ingredient.amountUnit.measureId
                        |> flip Dict.get measureMap
                        |> Maybe.map .name
                    )
                ]
            ]
        , button [ class "button", onClick (SaveIngredientEdit namedIngredient.ingredient.id) ]
            [ text "Save" ]
        , button [ class "button", onClick (ExitEditIngredientAt namedIngredient.ingredient.id) ]
            [ text "Cancel" ]
        ]


viewFoodLine : FoodMap -> MeasureMap -> List IngredientCreationClientInput -> Food -> Html Msg
viewFoodLine foodMap measureMap ingredientsToAdd food =
    let
        saveOnEnter =
            onEnter (AddFood food.id)

        process =
            case List.Extra.find (\i -> i.foodId == food.id) ingredientsToAdd of
                Nothing ->
                    [ td [] [ button [ class "button", onClick (SelectFood food) ] [ text "Select" ] ] ]

                Just ingredientToAdd ->
                    [ td []
                        [ div [ class "amount" ]
                            [ label [] [ text "Amount" ]
                            , input
                                [ ingredientToAdd.amountUnit.factor.text |> value
                                , onInput
                                    (flip
                                        (ValidatedInput.lift
                                            (IngredientCreationClientInput.amountUnit
                                                |> Compose.lensWithLens AmountUnitClientInput.factor
                                            )
                                        ).set
                                        ingredientToAdd
                                        >> UpdateAddFood
                                    )
                                , saveOnEnter
                                ]
                                []
                            ]
                        ]
                    , div [ class "unit" ]
                        [ label [] [ text "Unit" ]
                        , div [ class "unit" ]
                            [ dropdown
                                { items =
                                    foodMap
                                        |> Dict.get food.id
                                        |> Maybe.Extra.unpack (\_ -> []) .measures
                                        |> List.map (\m -> { value = String.fromInt m.id, text = m.name, enabled = True })
                                , emptyItem =
                                    Just
                                        { value = String.fromInt ingredientToAdd.amountUnit.measureId
                                        , text =
                                            measureMap
                                                |> Dict.get ingredientToAdd.amountUnit.measureId
                                                |> Maybe.Extra.unpack (\_ -> "") .name
                                        , enabled = True
                                        }
                                , onChange =
                                    Maybe.andThen String.toInt
                                        >> Maybe.withDefault ingredientToAdd.amountUnit.measureId
                                        >> flip (IngredientCreationClientInput.amountUnit |> Compose.lensWithLens AmountUnitClientInput.measureId).set ingredientToAdd
                                        >> UpdateAddFood
                                }
                                []
                                (ingredientToAdd.amountUnit.measureId |> String.fromInt |> Just)
                            ]
                        ]

                    -- todo: Disable button for missing amount/unit
                    , td [] [ button [ class "button", onClick (AddFood food.id) ] [ text "Add" ] ]
                    , td [] [ button [ class "button", onClick (DeselectFood food.id) ] [ text "Cancel" ] ]
                    ]
    in
    tr [ id "addingFoodLine" ]
        (td [] [ label [] [ text food.name ] ]
            :: process
        )


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
                    ( foods
                        |> List.map (\f -> ( f.id, f ))
                        |> Dict.fromList
                        |> flip foodsLens.set model
                    , foods
                        |> Encode.list encoderFood
                        |> Encode.encode 0
                        |> storeFoods
                    )

                _ ->
                    ( model, Cmd.none )

        SetFoodsSearchString string ->
            ( foodsSearchStringLens.set string model, Cmd.none )

        SelectFood food ->
            ( model
                |> (foodsToAdd |> Compose.lensWithOptional (LensUtil.firstSuch (\x -> x.foodId == food.id))).set
                    (IngredientCreationClientInput.default model.recipeId food.id (food.measures |> List.head |> Maybe.Extra.unpack (\_ -> 0) .id))
            , Cmd.none
            )

        DeselectFood foodId ->
            ( model
                |> foodsToAdd.set (List.filter (\f -> f.foodId /= foodId) model.foodsToAdd)
            , Cmd.none
            )

        AddFood foodId ->
            case List.Extra.find (\f -> f.foodId == foodId) model.foodsToAdd of
                Nothing ->
                    ( model, Cmd.none )

                Just foodToAdd ->
                    ( model
                    , foodToAdd
                        |> IngredientCreationClientInput.toCreation
                        |> (\ic ->
                                addFood
                                    { configuration = model.configuration
                                    , jwt = model.jwt
                                    , ingredientCreation = ic
                                    }
                           )
                    )

        UpdateAddFood ingredientCreationClientInput ->
            ( model.foodsToAdd
                |> List.Extra.setIf (\f -> f.foodId == ingredientCreationClientInput.foodId) ingredientCreationClientInput
                |> flip foodsToAdd.set model
            , Cmd.none
            )


fetchIngredients : { configuration : Configuration, jwt : JWT, recipeId : RecipeId } -> Cmd Msg
fetchIngredients ps =
    HttpUtil.getJsonWithJWT ps.jwt
        { url = String.join "/" [ ps.configuration.backendURL, "recipe", ps.recipeId, "ingredients" ]
        , expect = HttpUtil.expectJson GotFetchIngredientsResponse (Decode.list decoderIngredient)
        }


addFood : { configuration : Configuration, jwt : JWT, ingredientCreation : IngredientCreation } -> Cmd Msg
addFood ps =
    HttpUtil.patchJsonWithJWT ps.jwt
        { url = String.join "/" [ ps.configuration.backendURL, "recipe", "add-ingredient" ]
        , body = encoderIngredientCreation ps.ingredientCreation
        , expect = HttpUtil.expectJson GotAddIngredientResponse decoderIngredient
        }


special : Int -> String
special =
    Char.fromCode >> String.fromChar
