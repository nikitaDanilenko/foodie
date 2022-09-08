module Pages.Meals.Msg exposing (Msg, update, updateJWT)

import Api.Auxiliary exposing (JWT, MealId)
import Api.Types.Meal exposing (Meal, decoderMeal)
import Api.Types.MealCreation exposing (encoderMealCreation)
import Api.Types.MealUpdate exposing (MealUpdate, encoderMealUpdate)
import Configuration exposing (Configuration)
import Either exposing (Either(..))
import Http exposing (Error)
import Json.Decode as Decode
import List.Extra
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Monocle.Optional as Optional
import Pages.Meals.Model
import Ports exposing (doFetchToken)
import Url.Builder
import Util.Editing as Editing
import Util.HttpUtil as HttpUtil
import Util.LensUtil as LensUtil


type Msg
    = CreateMeal
    | GotCreateMealResponse (Result Error Meal)
    | UpdateMeal MealUpdate
    | SaveMealEdit MealId
    | GotSaveMealResponse (Result Error Meal)
    | EnterEditMeal MealId
    | ExitEditMealAt MealId
    | DeleteMeal MealId
    | GotDeleteMealResponse MealId (Result Error ())
    | GotFetchMealsResponse (Result Error (List Meal))
    | UpdateJWT String


updateJWT : String -> Msg
updateJWT =
    UpdateJWT


init : Pages.Meals.Model.Flags -> ( Pages.Meals.Model.Model, Cmd Msg )
init flags =
    let
        ( jwt, cmd ) =
            flags.jwt
                |> Maybe.Extra.unwrap
                    ( "", doFetchToken () )
                    (\t -> ( t, fetchMeals flags.configuration t ))
    in
    ( { configuration = flags.configuration
      , jwt = jwt
      , meals = []
      , mealsToAdd = []
      }
    , cmd
    )


update : Msg -> Pages.Meals.Model.Model -> ( Pages.Meals.Model.Model, Cmd Msg )
update msg model =
    case msg of
        CreateMeal ->
            ( model
            , handleCreateMeal model
            )

        GotCreateMealResponse dataOrError ->
            handleCreateMealResponse model dataOrError

        UpdateMeal mealUpdate ->
            ( handleUpdateMeal model mealUpdate
            , Cmd.none
            )

        SaveMealEdit mealId ->
            ( model
            , handleSaveMealUpdate model mealId
            )

        GotSaveMealResponse dataOrError ->
            ( handleGotSaveMealResponse model dataOrError
            , Cmd.none
            )

        EnterEditMeal mealId ->
            ( handleEnterEditMeal model mealId
            , Cmd.none
            )

        ExitEditMealAt mealId ->
            ( handleExitEditMealAt model mealId
            , Cmd.none
            )

        DeleteMeal mealId ->
            ( model
            , handleDeleteMeal model mealId
            )

        GotDeleteMealResponse deletedId dataOrError ->
            ( handleGotDeleteMealResponse model deletedId dataOrError
            , Cmd.none
            )

        GotFetchMealsResponse dataOrError ->
            ( handleGotFetchMealsResponse model dataOrError
            , Cmd.none
            )

        UpdateJWT jwt ->
            handleUpdateJWT model jwt


handleCreateMeal model =
    let
        -- todo: Either use the current day as a base or switch to a proper creation entirely
        defaultMealCreation =
            { date =
                { date =
                    { year = 2022
                    , month = 1
                    , day = 1
                    }
                , time = Nothing
                }
            , name = Nothing
            , amount = 0
            }
    in
    HttpUtil.postJsonWithJWT model.jwt
        { url = Url.Builder.relative [ model.configuration.backendURL, "meal", "create" ] []
        , body = encoderMealCreation defaultMealCreation
        , expect = HttpUtil.expectJson GotCreateMealResponse decoderMeal
        }


handleCreateMealResponse model dataOrError =
    case dataOrError of
        Ok meal ->
            let
                newModel =
                    Lens.modify Pages.Meals.Model.lens.meals
                        (\ts ->
                            Right
                                { original = meal
                                , update = mealUpdateFromMeal meal
                                }
                                :: ts
                        )
                        model
            in
            ( newModel, Cmd.none )

        _ ->
            -- todo: Handle error case
            ( model, Cmd.none )


handleUpdateMeal : Pages.Meals.Model.Model -> MealUpdate -> Pages.Meals.Model.Model
handleUpdateMeal model mealUpdate =
    model
        |> mapMealOrUpdateById mealUpdate.id
            (Either.mapRight (Editing.updateLens.set mealUpdate))


handleSaveMealUpdate model mealId =
    Maybe.Extra.unwrap
        Cmd.none
        (Either.unwrap Cmd.none
            (.update
                >> saveMeal model
            )
        )
        (List.Extra.find (Editing.is .id mealId) model.meals)


handleGotSaveMealResponse model dataOrError =
    case dataOrError of
        Ok meal ->
            model
                |> mapMealOrUpdateById meal.id
                    (Either.andThenRight (always (Left meal)))

        -- todo: Handle error case
        _ ->
            model


handleEnterEditMeal : Pages.Meals.Model.Model -> MealId -> Pages.Meals.Model.Model
handleEnterEditMeal model mealId =
    model
        |> mapMealOrUpdateById mealId
            (Either.unpack (\meal -> { original = meal, update = mealUpdateFromMeal meal }) identity >> Right)


handleExitEditMealAt : Pages.Meals.Model.Model -> MealId -> Pages.Meals.Model.Model
handleExitEditMealAt model mealId =
    model |> mapMealOrUpdateById mealId (Either.unpack identity .original >> Left)


handleDeleteMeal : Pages.Meals.Model.Model -> MealId -> Cmd Msg
handleDeleteMeal model mealId =
    HttpUtil.deleteWithJWT model.jwt
        { url = Url.Builder.relative [ model.configuration.backendURL, "meal", "delete", mealId ] []
        , expect = HttpUtil.expectWhatever (GotDeleteMealResponse mealId)
        }


handleGotDeleteMealResponse model deletedId dataOrError =
    case dataOrError of
        Ok _ ->
            model
                |> Pages.Meals.Model.lens.meals.set
                    (model.meals
                        |> List.Extra.filterNot
                            (Either.unpack
                                (\t -> t.id == deletedId)
                                (\t -> t.original.id == deletedId)
                            )
                    )

        -- todo: Handle error case
        _ ->
            model


handleGotFetchMealsResponse model dataOrError =
    case dataOrError of
        Ok ownMeals ->
            model |> Pages.Meals.Model.lens.meals.set (ownMeals |> List.map Left)

        -- todo: Handle error case
        _ ->
            model


handleUpdateJWT model jwt =
    ( Pages.Meals.Model.lens.jwt.set jwt model
    , fetchMeals model.configuration model.jwt
    )


mealUpdateFromMeal : Meal -> MealUpdate
mealUpdateFromMeal meal =
    { id = meal.id
    , date = meal.date
    , name = meal.name
    }


mapMealOrUpdateById : MealId -> (Pages.Meals.Model.MealOrUpdate -> Pages.Meals.Model.MealOrUpdate) -> Pages.Meals.Model.Model -> Pages.Meals.Model.Model
mapMealOrUpdateById mealId =
    Pages.Meals.Model.lens.meals
        |> Compose.lensWithOptional (mealId |> Editing.is .id |> LensUtil.firstSuch)
        |> Optional.modify


fetchMeals : Configuration -> JWT -> Cmd Msg
fetchMeals conf jwt =
    HttpUtil.getJsonWithJWT jwt
        { url = Url.Builder.relative [ conf.backendURL, "meal", "all" ] []
        , expect = HttpUtil.expectJson GotFetchMealsResponse (Decode.list decoderMeal)
        }


saveMeal : Pages.Meals.Model.Model -> MealUpdate -> Cmd Msg
saveMeal model mealUpdate =
    HttpUtil.patchJsonWithJWT model.jwt
        { url = Url.Builder.relative [ model.configuration.backendURL, "meal", "update" ] []
        , body = encoderMealUpdate mealUpdate
        , expect = HttpUtil.expectJson GotSaveMealResponse decoderMeal
        }
