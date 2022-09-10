module Pages.Meals.Handler exposing (init, update, updateJWT)

import Api.Auxiliary exposing (JWT, MealId)
import Api.Types.Meal exposing (Meal)
import Api.Types.MealUpdate exposing (MealUpdate)
import Basics.Extra exposing (flip)
import Either exposing (Either(..))
import Http exposing (Error)
import List.Extra
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Monocle.Optional as Optional
import Pages.Meals.Page as Page
import Pages.Meals.Requests as Requests
import Ports exposing (doFetchToken)
import Util.Editing as Editing exposing (Editing)
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    let
        ( jwt, cmd ) =
            flags.jwt
                |> Maybe.Extra.unwrap
                    ( "", doFetchToken () )
                    (\t ->
                        ( t
                        , Requests.fetchMeals
                            { configuration = flags.configuration
                            , jwt = t
                            }
                        )
                    )
    in
    ( { flagsWithJWT =
            { configuration = flags.configuration
            , jwt = jwt
            }
      , meals = []
      , mealsToAdd = []
      }
    , cmd
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.CreateMeal ->
            createMeal model

        Page.GotCreateMealResponse dataOrError ->
            gotCreateMealResponse model dataOrError

        Page.UpdateMeal mealUpdate ->
            updateMeal model mealUpdate

        Page.SaveMealEdit mealId ->
            saveMealEdit model mealId

        Page.GotSaveMealResponse dataOrError ->
            gotSaveMealResponse model dataOrError

        Page.EnterEditMeal mealId ->
            enterEditMeal model mealId

        Page.ExitEditMealAt mealId ->
            exitEditMealAt model mealId

        Page.DeleteMeal mealId ->
            deleteMeal model mealId

        Page.GotDeleteMealResponse deletedId dataOrError ->
            gotDeleteMealResponse model deletedId dataOrError

        Page.GotFetchMealsResponse dataOrError ->
            gotFetchMealsResponse model dataOrError

        Page.UpdateJWT jwt ->
            updateJWT model jwt


createMeal : Page.Model -> ( Page.Model, Cmd Page.Msg )
createMeal model =
    ( model
    , Requests.createMeal model.flagsWithJWT
    )


gotCreateMealResponse : Page.Model -> Result Error Meal -> ( Page.Model, Cmd msg )
gotCreateMealResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unwrap model
            (\meal ->
                Lens.modify Page.lenses.meals
                    (\ts ->
                        Right
                            { original = meal
                            , update = mealUpdateFromMeal meal
                            }
                            :: ts
                    )
                    model
            )
    , Cmd.none
    )


updateMeal : Page.Model -> MealUpdate -> ( Page.Model, Cmd Page.Msg )
updateMeal model mealUpdate =
    ( model
        |> mapMealOrUpdateById mealUpdate.id
            (Either.mapRight (Editing.updateLens.set mealUpdate))
    , Cmd.none
    )


saveMealEdit : Page.Model -> MealId -> ( Page.Model, Cmd Page.Msg )
saveMealEdit model mealId =
    ( model
    , Maybe.Extra.unwrap
        Cmd.none
        (Either.unwrap Cmd.none
            (.update
                >> Requests.saveMeal model.flagsWithJWT
            )
        )
        (List.Extra.find (Editing.is .id mealId) model.meals)
    )


gotSaveMealResponse : Page.Model -> Result Error Meal -> ( Page.Model, Cmd Page.Msg )
gotSaveMealResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unwrap model
            (\meal ->
                model
                    |> mapMealOrUpdateById meal.id
                        (Either.andThenRight (always (Left meal)))
            )
    , Cmd.none
    )


enterEditMeal : Page.Model -> MealId -> ( Page.Model, Cmd Page.Msg )
enterEditMeal model mealId =
    ( model
        |> mapMealOrUpdateById mealId
            (Either.unpack (\meal -> { original = meal, update = mealUpdateFromMeal meal }) identity >> Right)
    , Cmd.none
    )


exitEditMealAt : Page.Model -> MealId -> ( Page.Model, Cmd Page.Msg )
exitEditMealAt model mealId =
    ( model |> mapMealOrUpdateById mealId (Either.andThen (.original >> Left))
    , Cmd.none
    )


deleteMeal : Page.Model -> MealId -> ( Page.Model, Cmd Page.Msg )
deleteMeal model mealId =
    ( model
    , Requests.deleteMeal model.flagsWithJWT mealId
    )


gotDeleteMealResponse : Page.Model -> MealId -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteMealResponse model deletedId dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unwrap model
            (\_ ->
                Lens.modify Page.lenses.meals
                    (List.Extra.filterNot (mealIdIs deletedId))
                    model
            )
    , Cmd.none
    )


gotFetchMealsResponse : Page.Model -> Result Error (List Meal) -> ( Page.Model, Cmd Page.Msg )
gotFetchMealsResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unwrap model (List.map Left >> flip Page.lenses.meals.set model)
    , Cmd.none
    )


updateJWT : Page.Model -> JWT -> ( Page.Model, Cmd Page.Msg )
updateJWT model jwt =
    let
        newModel =
            Page.lenses.jwt.set jwt model
    in
    ( newModel
    , Requests.fetchMeals newModel.flagsWithJWT
    )


mealUpdateFromMeal : Meal -> MealUpdate
mealUpdateFromMeal meal =
    { id = meal.id
    , date = meal.date
    , name = meal.name
    }


mapMealOrUpdateById : MealId -> (Page.MealOrUpdate -> Page.MealOrUpdate) -> Page.Model -> Page.Model
mapMealOrUpdateById mealId =
    Page.lenses.meals
        |> Compose.lensWithOptional (mealId |> Editing.is .id |> LensUtil.firstSuch)
        |> Optional.modify


mealIdIs : MealId -> Either Meal (Editing Meal MealUpdate) -> Bool
mealIdIs mealId =
    Either.unpack
        (\i -> i.id == mealId)
        (\e -> e.original.id == mealId)
