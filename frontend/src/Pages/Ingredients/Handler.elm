module Pages.Ingredients.Handler exposing (init, update)

import Api.Auxiliary exposing (FoodId, IngredientId, JWT, MeasureId, RecipeId)
import Api.Types.Food exposing (Food, decoderFood, encoderFood)
import Api.Types.Ingredient exposing (Ingredient)
import Api.Types.Measure exposing (Measure, decoderMeasure, encoderMeasure)
import Api.Types.Recipe exposing (Recipe)
import Basics.Extra exposing (flip)
import Dict exposing (Dict)
import Either exposing (Either(..))
import Http exposing (Error)
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens as Lens exposing (Lens)
import Monocle.Optional as Optional
import Pages.Ingredients.IngredientCreationClientInput as IngredientCreationClientInput exposing (IngredientCreationClientInput)
import Pages.Ingredients.IngredientUpdateClientInput as IngredientUpdateClientInput exposing (IngredientUpdateClientInput)
import Pages.Ingredients.Page as Page
import Pages.Ingredients.RecipeInfo as RecipeInfo exposing (RecipeInfo)
import Pages.Ingredients.Requests as Requests
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Ports exposing (doFetchFoods, doFetchMeasures, doFetchToken, storeFoods, storeMeasures)
import Util.Editing as Editing exposing (Editing)
import Util.LensUtil as LensUtil


initialFetch : FlagsWithJWT -> RecipeId -> Cmd Page.Msg
initialFetch flags recipeId =
    Cmd.batch
        [ Requests.fetchIngredients flags recipeId
        , Requests.fetchRecipe flags recipeId
        , doFetchFoods ()
        , doFetchMeasures ()
        ]


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    let
        ( jwt, cmd ) =
            flags.jwt
                |> Maybe.Extra.unwrap
                    ( "", doFetchToken () )
                    (\token ->
                        ( token
                        , initialFetch
                            { configuration = flags.configuration
                            , jwt = token
                            }
                            flags.recipeId
                        )
                    )
    in
    ( { flagsWithJWT =
            { configuration = flags.configuration
            , jwt = jwt
            }
      , recipeId = flags.recipeId
      , ingredients = Dict.empty
      , foods = Dict.empty
      , measures = Dict.empty
      , foodsSearchString = ""
      , foodsToAdd = Dict.empty
      , recipeInfo = Nothing
      }
    , cmd
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.UpdateIngredient ingredientUpdate ->
            updateIngredient model ingredientUpdate

        Page.SaveIngredientEdit ingredientId ->
            saveIngredientEdit model ingredientId

        Page.GotSaveIngredientResponse result ->
            gotSaveIngredientResponse model result

        Page.EnterEditIngredient ingredientId ->
            enterEditIngredient model ingredientId

        Page.ExitEditIngredientAt ingredientId ->
            exitEditIngredientAt model ingredientId

        Page.DeleteIngredient ingredientId ->
            deleteIngredient model ingredientId

        Page.GotDeleteIngredientResponse ingredientId result ->
            gotDeleteIngredientResponse model ingredientId result

        Page.GotFetchIngredientsResponse result ->
            gotFetchIngredientsResponse model result

        Page.GotFetchFoodsResponse result ->
            gotFetchFoodsResponse model result

        Page.GotFetchMeasuresResponse result ->
            gotFetchMeasuresResponse model result

        Page.GotFetchRecipeResponse result ->
            gotFetchRecipeResponse model result

        Page.UpdateJWT token ->
            updateJWT model token

        Page.UpdateFoods string ->
            updateFoods model string

        Page.UpdateMeasures string ->
            updateMeasures model string

        Page.SetFoodsSearchString string ->
            setFoodsSearchString model string

        Page.SelectFood food ->
            selectFood model food

        Page.DeselectFood foodId ->
            deselectFood model foodId

        Page.AddFood foodId ->
            addFood model foodId

        Page.GotAddFoodResponse result ->
            gotAddFoodResponse model result

        Page.UpdateAddFood ingredientCreationClientInput ->
            updateAddFood model ingredientCreationClientInput


mapIngredientOrUpdateById : IngredientId -> (Page.IngredientOrUpdate -> Page.IngredientOrUpdate) -> Page.Model -> Page.Model
mapIngredientOrUpdateById ingredientId =
    Page.lenses.ingredients
        |> Compose.lensWithOptional (LensUtil.dictByKey ingredientId)
        |> Optional.modify


updateIngredient : Page.Model -> IngredientUpdateClientInput -> ( Page.Model, Cmd msg )
updateIngredient model ingredientUpdate =
    ( model
        |> mapIngredientOrUpdateById ingredientUpdate.ingredientId
            (Either.mapRight (Editing.updateLens.set ingredientUpdate))
    , Cmd.none
    )


saveIngredientEdit : Page.Model -> IngredientId -> ( Page.Model, Cmd Page.Msg )
saveIngredientEdit model ingredientId =
    ( model
    , model
        |> Page.lenses.ingredients.get
        |> Dict.get ingredientId
        |> Maybe.andThen Either.rightToMaybe
        |> Maybe.Extra.unwrap Cmd.none
            (.update >> IngredientUpdateClientInput.to >> Requests.saveIngredient model.flagsWithJWT)
    )


gotSaveIngredientResponse : Page.Model -> Result Error Ingredient -> ( Page.Model, Cmd msg )
gotSaveIngredientResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unwrap model
            (\ingredient ->
                model
                    |> mapIngredientOrUpdateById ingredient.id
                        (Either.andThenRight (always (Left ingredient)))
            )
    , Cmd.none
    )


enterEditIngredient : Page.Model -> IngredientId -> ( Page.Model, Cmd Page.Msg )
enterEditIngredient model ingredientId =
    ( model
        |> mapIngredientOrUpdateById ingredientId (Either.andThenLeft (\i -> Right { original = i, update = IngredientUpdateClientInput.from i }))
    , Cmd.none
    )


exitEditIngredientAt : Page.Model -> IngredientId -> ( Page.Model, Cmd Page.Msg )
exitEditIngredientAt model ingredientId =
    ( model
        |> mapIngredientOrUpdateById ingredientId (Either.andThen (.original >> Left))
    , Cmd.none
    )


deleteIngredient : Page.Model -> IngredientId -> ( Page.Model, Cmd Page.Msg )
deleteIngredient model ingredientId =
    ( model
    , Requests.deleteIngredient model.flagsWithJWT ingredientId
    )


gotDeleteIngredientResponse : Page.Model -> IngredientId -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteIngredientResponse model ingredientId result =
    ( result
        |> Either.fromResult
        |> Either.unwrap model
            (model
                |> Lens.modify Page.lenses.ingredients
                    (Dict.remove ingredientId)
                |> always
            )
    , Cmd.none
    )


gotFetchIngredientsResponse : Page.Model -> Result Error (List Ingredient) -> ( Page.Model, Cmd Page.Msg )
gotFetchIngredientsResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unwrap model
            (List.map (\ingredient -> ( ingredient.id, Left ingredient ))
                >> Dict.fromList
                >> flip Page.lenses.ingredients.set model
            )
    , Cmd.none
    )


gotFetchFoodsResponse : Page.Model -> Result Error (List Food) -> ( Page.Model, Cmd Page.Msg )
gotFetchFoodsResponse model result =
    result
        |> Either.fromResult
        |> Either.unwrap ( model, Cmd.none )
            (\foods ->
                ( LensUtil.set foods .id Page.lenses.foods model
                , foods
                    |> Encode.list encoderFood
                    |> Encode.encode 0
                    |> storeFoods
                )
            )


gotFetchMeasuresResponse : Page.Model -> Result Error (List Measure) -> ( Page.Model, Cmd Page.Msg )
gotFetchMeasuresResponse model result =
    result
        |> Either.fromResult
        |> Either.unwrap ( model, Cmd.none )
            (\measures ->
                ( LensUtil.set measures .id Page.lenses.measures model
                , measures
                    |> Encode.list encoderMeasure
                    |> Encode.encode 0
                    |> storeMeasures
                )
            )


gotFetchRecipeResponse : Page.Model -> Result Error Recipe -> ( Page.Model, Cmd Page.Msg )
gotFetchRecipeResponse model result =
    ( result
        |> Result.map
            (RecipeInfo.from
                >> Just
                >> flip Page.lenses.recipeInfo.set model
            )
        |> Result.withDefault model
    , Cmd.none
    )


updateJWT : Page.Model -> JWT -> ( Page.Model, Cmd Page.Msg )
updateJWT model token =
    let
        newModel =
            Page.lenses.jwt.set token model
    in
    ( newModel
    , initialFetch newModel.flagsWithJWT model.recipeId
    )


updateFoods : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
updateFoods model =
    Decode.decodeString (Decode.list decoderFood)
        >> Result.toMaybe
        >> Maybe.Extra.unwrap ( model, Cmd.none )
            (\foods ->
                ( LensUtil.set foods .id Page.lenses.foods model
                , if List.isEmpty foods then
                    Requests.fetchFoods model.flagsWithJWT

                  else
                    Cmd.none
                )
            )


updateMeasures : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
updateMeasures model =
    Decode.decodeString (Decode.list decoderMeasure)
        >> Result.toMaybe
        >> Maybe.Extra.unwrap ( model, Cmd.none )
            (\measures ->
                ( LensUtil.set measures .id Page.lenses.measures model
                , if List.isEmpty measures then
                    Requests.fetchMeasures model.flagsWithJWT

                  else
                    Cmd.none
                )
            )


setFoodsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setFoodsSearchString model string =
    ( Page.lenses.foodsSearchString.set string model
    , Cmd.none
    )


selectFood : Page.Model -> Food -> ( Page.Model, Cmd msg )
selectFood model food =
    ( model
        |> Lens.modify Page.lenses.foodsToAdd
            (Dict.update food.id (always (IngredientCreationClientInput.default model.recipeId food.id (food.measures |> List.head |> Maybe.Extra.unwrap 0 .id)) >> Just))
    , Cmd.none
    )


deselectFood : Page.Model -> FoodId -> ( Page.Model, Cmd Page.Msg )
deselectFood model foodId =
    ( model
        |> Lens.modify Page.lenses.foodsToAdd (Dict.remove foodId)
    , Cmd.none
    )


addFood : Page.Model -> FoodId -> ( Page.Model, Cmd Page.Msg )
addFood model foodId =
    ( model
    , model
        |> (Page.lenses.foodsToAdd
                |> Compose.lensWithOptional (LensUtil.dictByKey foodId)
           ).getOption
        |> Maybe.Extra.unwrap Cmd.none
            (\foodToAdd ->
                foodToAdd
                    |> IngredientCreationClientInput.toCreation
                    |> (\ic ->
                            Requests.addFood
                                { configuration = model.flagsWithJWT.configuration
                                , jwt = model.flagsWithJWT.jwt
                                , ingredientCreation = ic
                                }
                       )
            )
    )


gotAddFoodResponse : Page.Model -> Result Error Ingredient -> ( Page.Model, Cmd Page.Msg )
gotAddFoodResponse model result =
    ( result
        |> Either.fromResult
        |> Either.unwrap model
            (\ingredient ->
                model
                    |> Lens.modify
                        Page.lenses.ingredients
                        (Dict.update ingredient.id (always ingredient >> Left >> Just))
                    |> Lens.modify
                        Page.lenses.foodsToAdd
                        (Dict.remove ingredient.foodId)
            )
    , Cmd.none
    )


updateAddFood : Page.Model -> IngredientCreationClientInput -> ( Page.Model, Cmd Page.Msg )
updateAddFood model ingredientCreationClientInput =
    ( model
        |> Lens.modify Page.lenses.foodsToAdd
            (Dict.update ingredientCreationClientInput.foodId (always ingredientCreationClientInput >> Just))
    , Cmd.none
    )
