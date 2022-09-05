module Pages.IngredientEditor.IngredientEditor exposing (Flags, Model, Msg, init, update, updateFoods, updateJWT, updateMeasures, view)

import Api.Auxiliary exposing (FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.Food exposing (Food, decoderFood, encoderFood)
import Api.Types.Ingredient exposing (Ingredient, decoderIngredient)
import Api.Types.IngredientCreation exposing (IngredientCreation, encoderIngredientCreation)
import Api.Types.Measure exposing (Measure, decoderMeasure, encoderMeasure)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Dict exposing (Dict)
import Dropdown exposing (dropdown)
import Either exposing (Either(..))
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
import Monocle.Lens as Lens exposing (Lens)
import Monocle.Optional as Optional
import Pages.IngredientEditor.AmountUnitClientInput as AmountUnitClientInput
import Pages.IngredientEditor.IngredientCreationClientInput as IngredientCreationClientInput exposing (IngredientCreationClientInput)
import Pages.IngredientEditor.IngredientUpdateClientInput as IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.Util.ValidatedInput as ValidatedInput
import Ports exposing (doFetchFoods, doFetchMeasures, doFetchToken, storeFoods, storeMeasures)
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil as HttpUtil
import Util.LensUtil as LensUtil
import Util.ListUtil as ListUtil


type alias Model =
    { configuration : Configuration
    , jwt : String
    , recipeId : RecipeId
    , ingredients : List (Either Ingredient (Editing Ingredient IngredientUpdateClientInput))
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


measuresLens : Lens Model MeasureMap
measuresLens =
    Lens .measures (\b a -> { a | measures = b })


ingredientsLens : Lens Model (List (Either Ingredient (Editing Ingredient IngredientUpdateClientInput)))
ingredientsLens =
    Lens .ingredients (\b a -> { a | ingredients = b })


foodsToAddLens : Lens Model (List IngredientCreationClientInput)
foodsToAddLens =
    Lens .foodsToAdd (\b a -> { a | foodsToAdd = b })


foodsSearchStringLens : Lens Model String
foodsSearchStringLens =
    Lens .foodsSearchString (\b a -> { a | foodsSearchString = b })


type Msg
    = UpdateIngredient IngredientId IngredientUpdateClientInput
    | SaveIngredientEdit IngredientId
    | GotSaveIngredientResponse IngredientId (Result Error Ingredient)
    | EnterEditIngredient IngredientId
    | ExitEditIngredientAt IngredientId
    | DeleteIngredient IngredientId
    | GotDeleteIngredientResponse IngredientId (Result Error ())
    | GotFetchIngredientsResponse (Result Error (List Ingredient))
    | GotFetchFoodsResponse (Result Error (List Food))
    | GotFetchMeasuresResponse (Result Error (List Measure))
    | SelectFood Food
    | DeselectFood FoodId
    | AddFood FoodId
    | GotAddFoodResponse (Result Error Ingredient)
    | UpdateAddFood IngredientCreationClientInput
    | UpdateJWT String
    | UpdateFoods String
    | UpdateMeasures String
    | SetFoodsSearchString String


updateJWT : String -> Msg
updateJWT =
    UpdateJWT


updateFoods : String -> Msg
updateFoods =
    UpdateFoods


updateMeasures : String -> Msg
updateMeasures =
    UpdateMeasures


type alias Flags =
    { configuration : Configuration
    , jwt : Maybe JWT
    , recipeId : RecipeId
    }


type alias FlagsWithJWT =
    { configuration : Configuration, jwt : JWT, recipeId : RecipeId }


initialFetch : FlagsWithJWT -> Cmd Msg
initialFetch flags =
    Cmd.batch
        [ fetchIngredients flags
        , doFetchFoods ()
        , doFetchMeasures ()
        ]


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( j, cmd ) =
            case flags.jwt of
                Just token ->
                    ( token
                    , initialFetch
                        { configuration = flags.configuration
                        , jwt = token
                        , recipeId = flags.recipeId
                        }
                    )

                Nothing ->
                    ( "", doFetchToken () )
    in
    ( { configuration = flags.configuration
      , jwt = j
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
                    (editOrDeleteIngredientLine model.measures model.foods)
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


ingredientNameOrEmpty : FoodMap -> FoodId -> String
ingredientNameOrEmpty fm fi =
    Dict.get fi fm |> Maybe.Extra.unpack (\_ -> "") .name


editOrDeleteIngredientLine : MeasureMap -> FoodMap -> Ingredient -> Html Msg
editOrDeleteIngredientLine measureMap foodMap ingredient =
    tr [ id "editingIngredient" ]
        [ td [] [ label [] [ ingredient.foodId |> ingredientNameOrEmpty foodMap |> text ] ]
        , td [] [ label [] [ ingredient.amountUnit.factor |> String.fromFloat |> text ] ]
        , td [] [ label [] [ ingredient.amountUnit.measureId |> flip Dict.get measureMap |> Maybe.Extra.unpack (always "") .name |> text ] ]
        , td [] [ button [ class "button", onClick (EnterEditIngredient ingredient.id) ] [ text "Edit" ] ]
        , td [] [ button [ class "button", onClick (DeleteIngredient ingredient.id) ] [ text "Delete" ] ]
        ]


editIngredientLine : MeasureMap -> FoodMap -> Ingredient -> IngredientUpdateClientInput -> Html Msg
editIngredientLine measureMap foodMap ingredient ingredientUpdateClientInput =
    let
        saveOnEnter =
            onEnter (SaveIngredientEdit ingredient.id)
    in
    -- todo: Check whether the update behaviour is correct. There is the implicit assumption that the update originates from the ingredient.
    --       cf. name, description
    div [ class "ingredientLine" ]
        [ div [ class "name" ]
            [ label [] [ text "Name" ]
            , label [] [ ingredient.foodId |> ingredientNameOrEmpty foodMap |> text ]
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
                        >> UpdateIngredient ingredient.id
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
                            |> Dict.get ingredient.foodId
                            |> Maybe.Extra.unpack (\_ -> []) .measures
                            |> List.map (\m -> { value = String.fromInt m.id, text = m.name, enabled = True })
                    , emptyItem =
                        Just
                            { value = String.fromInt ingredient.amountUnit.measureId
                            , text =
                                measureMap
                                    |> Dict.get ingredient.amountUnit.measureId
                                    |> Maybe.Extra.unpack (\_ -> "") .name
                            , enabled = True
                            }
                    , onChange =
                        Maybe.andThen String.toInt
                            >> Maybe.withDefault ingredientUpdateClientInput.amountUnit.measureId
                            >> flip (IngredientUpdateClientInput.amountUnit |> Compose.lensWithLens AmountUnitClientInput.measureId).set ingredientUpdateClientInput
                            >> UpdateIngredient ingredient.id
                    }
                    []
                    (ingredient.amountUnit.measureId
                        |> flip Dict.get measureMap
                        |> Maybe.map .name
                    )
                ]
            ]
        , button [ class "button", onClick (SaveIngredientEdit ingredient.id) ]
            [ text "Save" ]
        , button [ class "button", onClick (ExitEditIngredientAt ingredient.id) ]
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


ingredientIdIs : IngredientId -> Either Ingredient (Editing Ingredient IngredientUpdateClientInput) -> Bool
ingredientIdIs ingredientId =
    Either.unpack
        (\i -> i.id == ingredientId)
        (\e -> e.original.id == ingredientId)


foodIdOf : Either Ingredient (Editing Ingredient IngredientUpdateClientInput) -> FoodId
foodIdOf =
    Either.unpack
        .foodId
        (.original >> .foodId)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        fs =
            { configuration = model.configuration
            , jwt = model.jwt
            , recipeId = model.recipeId
            }

        set : List a -> (a -> comparable) -> Lens Model (Dict comparable a) -> Model -> Model
        set xs idOf lens md =
            xs
                |> List.map (\m -> ( idOf m, m ))
                |> Dict.fromList
                |> flip lens.set md
    in
    case msg of
        UpdateIngredient ingredientId ingredientUpdate ->
            ( model
                |> Optional.modify
                    (ingredientsLens |> Compose.lensWithOptional (LensUtil.firstSuch (ingredientIdIs ingredientId)))
                    (Either.mapRight (Editing.updateLens.set ingredientUpdate))
            , Cmd.none
            )

        SaveIngredientEdit ingredientId ->
            ( model, Cmd.none )

        GotSaveIngredientResponse ingredientId result ->
            ( model, Cmd.none )

        EnterEditIngredient ingredientId ->
            ( model
                |> Optional.modify (ingredientsLens |> Compose.lensWithOptional (LensUtil.firstSuch (ingredientIdIs ingredientId))) (Either.unpack (\i -> { original = i, update = IngredientUpdateClientInput.from i }) identity >> Right)
            , Cmd.none
            )

        ExitEditIngredientAt ingredientId ->
            ( model |> Optional.modify (ingredientsLens |> Compose.lensWithOptional (LensUtil.firstSuch (ingredientIdIs ingredientId))) (Either.unpack identity .original >> Left), Cmd.none )

        DeleteIngredient ingredientId ->
            ( model, deleteIngredient fs ingredientId )

        GotDeleteIngredientResponse ingredientId result ->
            case result of
                Ok _ ->
                    ( model
                        |> ingredientsLens.set
                            (model.ingredients
                                |> List.Extra.filterNot
                                    (ingredientIdIs ingredientId)
                            )
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        GotFetchIngredientsResponse result ->
            case result of
                Ok is ->
                    ( is
                        |> List.map Left
                        |> flip ingredientsLens.set model
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        GotFetchFoodsResponse result ->
            case result of
                Ok fds ->
                    ( set fds .id foodsLens model
                    , fds
                        |> Encode.list encoderFood
                        |> Encode.encode 0
                        |> storeFoods
                    )

                _ ->
                    ( model, Cmd.none )

        GotFetchMeasuresResponse result ->
            case result of
                Ok ms ->
                    ( set ms .id measuresLens model
                    , ms
                        |> Encode.list encoderMeasure
                        |> Encode.encode 0
                        |> storeMeasures
                    )

                _ ->
                    ( model, Cmd.none )

        UpdateJWT token ->
            ( jwtLens.set token model
            , initialFetch fs
            )

        UpdateFoods string ->
            case Decode.decodeString (Decode.list decoderFood) string of
                Ok fds ->
                    ( set fds .id foodsLens model
                    , if List.isEmpty fds then
                        fetchFoods fs

                      else
                        Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        UpdateMeasures string ->
            case Decode.decodeString (Decode.list decoderMeasure) string of
                Ok ms ->
                    ( set ms .id measuresLens model
                    , if List.isEmpty ms then
                        fetchMeasures fs

                      else
                        Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        SetFoodsSearchString string ->
            ( foodsSearchStringLens.set string model, Cmd.none )

        SelectFood food ->
            ( model
                |> (foodsToAddLens |> Compose.lensWithOptional (LensUtil.firstSuch (\x -> x.foodId == food.id))).set
                    (IngredientCreationClientInput.default model.recipeId food.id (food.measures |> List.head |> Maybe.Extra.unpack (\_ -> 0) .id))
            , Cmd.none
            )

        DeselectFood foodId ->
            ( model
                |> foodsToAddLens.set (List.filter (\f -> f.foodId /= foodId) model.foodsToAdd)
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

        GotAddFoodResponse result ->
            case result of
                Ok ingredient ->
                    ( model
                        |> Lens.modify
                            ingredientsLens
                            (ListUtil.insertBy
                                { compareA = .foodId >> ingredientNameOrEmpty model.foods
                                , compareB = foodIdOf >> ingredientNameOrEmpty model.foods
                                , mapAB = Left
                                }
                                ingredient
                            )
                        |> Lens.modify foodsToAddLens (List.Extra.filterNot (\ic -> ic.foodId == ingredient.foodId))
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        UpdateAddFood ingredientCreationClientInput ->
            ( model.foodsToAdd
                |> List.Extra.setIf (\f -> f.foodId == ingredientCreationClientInput.foodId) ingredientCreationClientInput
                |> flip foodsToAddLens.set model
            , Cmd.none
            )


fetchIngredients : FlagsWithJWT -> Cmd Msg
fetchIngredients flags =
    fetchList
        { addressSuffix = String.join "/" [ "recipe", flags.recipeId, "ingredients" ]
        , decoder = decoderIngredient
        , gotMsg = GotFetchIngredientsResponse
        }
        flags


fetchFoods : FlagsWithJWT -> Cmd Msg
fetchFoods =
    fetchList
        { addressSuffix = String.join "/" [ "recipe", "foods" ]
        , decoder = decoderFood
        , gotMsg = GotFetchFoodsResponse
        }


fetchMeasures : FlagsWithJWT -> Cmd Msg
fetchMeasures =
    fetchList
        { addressSuffix = String.join "/" [ "recipe", "measures" ]
        , decoder = decoderMeasure
        , gotMsg = GotFetchMeasuresResponse
        }


fetchList :
    { addressSuffix : String
    , decoder : Decode.Decoder a
    , gotMsg : Result Error (List a) -> Msg
    }
    -> FlagsWithJWT
    -> Cmd Msg
fetchList ps flags =
    HttpUtil.getJsonWithJWT flags.jwt
        { url = String.join "/" [ flags.configuration.backendURL, ps.addressSuffix ]
        , expect = HttpUtil.expectJson ps.gotMsg (Decode.list ps.decoder)
        }


addFood : { configuration : Configuration, jwt : JWT, ingredientCreation : IngredientCreation } -> Cmd Msg
addFood ps =
    HttpUtil.patchJsonWithJWT ps.jwt
        { url = String.join "/" [ ps.configuration.backendURL, "recipe", "add-ingredient" ]
        , body = encoderIngredientCreation ps.ingredientCreation
        , expect = HttpUtil.expectJson GotAddFoodResponse decoderIngredient
        }


deleteIngredient : FlagsWithJWT -> IngredientId -> Cmd Msg
deleteIngredient fs iid =
    HttpUtil.deleteWithJWT fs.jwt
        { url = String.join "/" [ fs.configuration.backendURL, "recipe", "remove-ingredient", iid ]
        , expect = HttpUtil.expectWhatever (GotDeleteIngredientResponse iid)
        }


special : Int -> String
special =
    Char.fromCode >> String.fromChar
