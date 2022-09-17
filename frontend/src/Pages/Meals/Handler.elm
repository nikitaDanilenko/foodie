module Pages.Meals.Handler exposing (init, update, updateJWT)

import Api.Auxiliary exposing (JWT, MealId)
import Api.Types.Meal exposing (Meal)
import Api.Types.MealUpdate exposing (MealUpdate)
import Basics.Extra exposing (flip)
import Dict
import Either exposing (Either(..))
import Http exposing (Error)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Monocle.Optional as Optional
import Pages.Meals.MealCreationClientInput as MealCreationClientInput exposing (MealCreationClientInput)
import Pages.Meals.Page as Page
import Pages.Meals.Requests as Requests
import Pages.Meals.Status as Status
import Ports exposing (doFetchToken)
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil as HttpUtil
import Util.Initialization as Initialization
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    let
        ( jwt, cmd ) =
            flags.jwt
                |> Maybe.Extra.unwrap
                    ( "", doFetchToken () )
                    (\token ->
                        ( token
                        , Requests.fetchMeals
                            { configuration = flags.configuration
                            , jwt = token
                            }
                        )
                    )
    in
    ( { flagsWithJWT =
            { configuration = flags.configuration
            , jwt = jwt
            }
      , meals = Dict.empty
      , mealToAdd = Nothing
      , initialization = Initialization.Loading (Status.initial |> Status.lenses.jwt.set (jwt |> String.isEmpty |> not))
      }
    , cmd
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.UpdateMealCreation mealCreationClientInput ->
            updateMealCreation model mealCreationClientInput

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


updateMealCreation : Page.Model -> Maybe MealCreationClientInput -> ( Page.Model, Cmd Page.Msg )
updateMealCreation model mealToAdd =
    ( model
        |> Page.lenses.mealToAdd.set mealToAdd
    , Cmd.none
    )


createMeal : Page.Model -> ( Page.Model, Cmd Page.Msg )
createMeal model =
    ( model
    , model.mealToAdd
        |> Maybe.Extra.unwrap Cmd.none (MealCreationClientInput.toCreation >> Requests.createMeal model.flagsWithJWT)
    )


gotCreateMealResponse : Page.Model -> Result Error Meal -> ( Page.Model, Cmd msg )
gotCreateMealResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\meal ->
                model
                    |> Lens.modify Page.lenses.meals
                        (Dict.insert meal.id (Left meal))
                    |> Page.lenses.mealToAdd.set Nothing
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
        (Dict.get mealId model.meals)
    )


gotSaveMealResponse : Page.Model -> Result Error Meal -> ( Page.Model, Cmd Page.Msg )
gotSaveMealResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
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
        |> Either.unpack (flip setError model)
            (\_ ->
                Lens.modify Page.lenses.meals
                    (Dict.remove deletedId)
                    model
            )
    , Cmd.none
    )


gotFetchMealsResponse : Page.Model -> Result Error (List Meal) -> ( Page.Model, Cmd Page.Msg )
gotFetchMealsResponse model dataOrError =
    ( dataOrError
        |> Either.fromResult
        |> Either.unpack (flip setError model)
            (\meals ->
                model
                    |> Page.lenses.meals.set
                        (meals
                            |> List.map (\meal -> ( meal.id, Left meal ))
                            |> Dict.fromList
                        )
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.meals).set True
            )
    , Cmd.none
    )


updateJWT : Page.Model -> JWT -> ( Page.Model, Cmd Page.Msg )
updateJWT model jwt =
    let
        newModel =
            model
                |> Page.lenses.jwt.set jwt
                |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.jwt).set True
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
        |> Compose.lensWithOptional (LensUtil.dictByKey mealId)
        |> Optional.modify


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
