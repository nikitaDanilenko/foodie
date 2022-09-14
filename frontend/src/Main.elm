module Main exposing (main)

import Basics.Extra exposing (flip)
import Browser exposing (UrlRequest)
import Browser.Navigation as Nav
import Configuration exposing (Configuration)
import Html exposing (Html, div, text)
import Monocle.Lens exposing (Lens)
import Pages.Ingredients.Handler
import Pages.Ingredients.Page
import Pages.Ingredients.View
import Pages.Login.Handler
import Pages.Login.Page
import Pages.Login.View
import Pages.MealEntries.Handler
import Pages.MealEntries.Page
import Pages.MealEntries.View
import Pages.Meals.Handler
import Pages.Meals.Page
import Pages.Meals.View
import Pages.Overview.Handler
import Pages.Overview.Page
import Pages.Overview.View
import Pages.Recipes.Handler
import Pages.Recipes.Page
import Pages.Recipes.View
import Pages.ReferenceNutrients.Handler
import Pages.ReferenceNutrients.Page
import Pages.ReferenceNutrients.View
import Pages.Statistics.Handler
import Pages.Statistics.Page
import Pages.Statistics.View
import Pages.Util.ParserUtil as ParserUtil
import Ports exposing (doFetchToken, fetchFoods, fetchMeasures, fetchNutrients, fetchToken)
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, s)


main : Program Configuration Model Msg
main =
    Browser.application
        { init = init
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        , subscriptions = subscriptions
        , update = update
        , view = \model -> { title = titleFor model, body = [ view model ] }
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ fetchToken FetchToken
        , fetchFoods FetchFoods
        , fetchMeasures FetchMeasures
        , fetchNutrients FetchNutrients
        ]


type alias Model =
    { key : Nav.Key
    , page : Page
    , configuration : Configuration
    , jwt : Maybe String
    }


jwtLens : Lens Model (Maybe String)
jwtLens =
    Lens .jwt (\b a -> { a | jwt = b })


type Page
    = Login Pages.Login.Page.Model
    | Overview Pages.Overview.Page.Model
    | Recipes Pages.Recipes.Page.Model
    | Ingredients Pages.Ingredients.Page.Model
    | Meals Pages.Meals.Page.Model
    | MealEntries Pages.MealEntries.Page.Model
    | Statistics Pages.Statistics.Page.Model
    | ReferenceNutrients Pages.ReferenceNutrients.Page.Model
    | NotFound


type Msg
    = ClickedLink UrlRequest
    | ChangedUrl Url
    | FetchToken String
    | FetchFoods String
    | FetchMeasures String
    | FetchNutrients String
    | LoginMsg Pages.Login.Page.Msg
    | OverviewMsg Pages.Overview.Page.Msg
    | RecipesMsg Pages.Recipes.Page.Msg
    | IngredientsMsg Pages.Ingredients.Page.Msg
    | MealsMsg Pages.Meals.Page.Msg
    | MealEntriesMsg Pages.MealEntries.Page.Msg
    | StatisticsMsg Pages.Statistics.Page.Msg
    | ReferenceNutrientsMsg Pages.ReferenceNutrients.Page.Msg


titleFor : Model -> String
titleFor _ =
    "Foodie"


init : Configuration -> Url -> Nav.Key -> ( Model, Cmd Msg )
init configuration url key =
    let
        ( model, cmd ) =
            stepTo url
                { page = NotFound
                , key = key
                , configuration = configuration
                , jwt = Nothing
                }
    in
    ( model, Cmd.batch [ doFetchToken (), cmd ] )


view : Model -> Html Msg
view model =
    case model.page of
        Login login ->
            Html.map LoginMsg (Pages.Login.View.view login)

        Overview overview ->
            Html.map OverviewMsg (Pages.Overview.View.view overview)

        Recipes recipes ->
            Html.map RecipesMsg (Pages.Recipes.View.view recipes)

        Ingredients ingredients ->
            Html.map IngredientsMsg (Pages.Ingredients.View.view ingredients)

        Meals meals ->
            Html.map MealsMsg (Pages.Meals.View.view meals)

        MealEntries mealEntries ->
            Html.map MealEntriesMsg (Pages.MealEntries.View.view mealEntries)

        Statistics statistics ->
            Html.map StatisticsMsg (Pages.Statistics.View.view statistics)

        ReferenceNutrients referenceNutrients ->
            Html.map ReferenceNutrientsMsg (Pages.ReferenceNutrients.View.view referenceNutrients)

        NotFound ->
            div [] [ text "Page not found" ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        ( ChangedUrl url, _ ) ->
            stepTo url model

        ( LoginMsg loginMsg, Login login ) ->
            stepThrough steps.login model (Pages.Login.Handler.update loginMsg login)

        -- todo: Check all cases, and possibly refactor to have less duplication.
        ( FetchToken token, page ) ->
            case page of
                Login _ ->
                    ( jwtLens.set (Just token) model, Cmd.none )

                Overview overview ->
                    stepThrough steps.overview model (Pages.Overview.Handler.update (Pages.Overview.Page.UpdateJWT token) overview)

                Recipes recipes ->
                    stepThrough steps.recipes model (Pages.Recipes.Handler.update (Pages.Recipes.Page.UpdateJWT token) recipes)

                Ingredients ingredients ->
                    stepThrough steps.ingredients model (Pages.Ingredients.Handler.update (Pages.Ingredients.Page.UpdateJWT token) ingredients)

                Meals meals ->
                    stepThrough steps.meals model (Pages.Meals.Handler.update (Pages.Meals.Page.UpdateJWT token) meals)

                MealEntries mealEntry ->
                    stepThrough steps.mealEntries model (Pages.MealEntries.Handler.update (Pages.MealEntries.Page.UpdateJWT token) mealEntry)

                Statistics statistics ->
                    stepThrough steps.statistics model (Pages.Statistics.Handler.update (Pages.Statistics.Page.UpdateJWT token) statistics)

                ReferenceNutrients referenceNutrients ->
                    stepThrough steps.referenceNutrients model (Pages.ReferenceNutrients.Handler.update (Pages.ReferenceNutrients.Page.UpdateJWT token) referenceNutrients)

                NotFound ->
                    ( jwtLens.set (Just token) model, Cmd.none )

        ( FetchFoods foods, Ingredients ingredients ) ->
            stepThrough steps.ingredients model (Pages.Ingredients.Handler.update (Pages.Ingredients.Page.UpdateFoods foods) ingredients)

        ( FetchMeasures measures, Ingredients ingredients ) ->
            stepThrough steps.ingredients model (Pages.Ingredients.Handler.update (Pages.Ingredients.Page.UpdateMeasures measures) ingredients)

        ( FetchNutrients nutrients, ReferenceNutrients referenceNutrients ) ->
            stepThrough steps.referenceNutrients model (Pages.ReferenceNutrients.Handler.update (Pages.ReferenceNutrients.Page.UpdateNutrients nutrients) referenceNutrients)

        ( OverviewMsg overviewMsg, Overview overview ) ->
            stepThrough steps.overview model (Pages.Overview.Handler.update overviewMsg overview)

        ( RecipesMsg recipesMsg, Recipes recipes ) ->
            stepThrough steps.recipes model (Pages.Recipes.Handler.update recipesMsg recipes)

        ( IngredientsMsg ingredientsMsg, Ingredients ingredients ) ->
            stepThrough steps.ingredients model (Pages.Ingredients.Handler.update ingredientsMsg ingredients)

        ( MealsMsg mealsMsg, Meals meals ) ->
            stepThrough steps.meals model (Pages.Meals.Handler.update mealsMsg meals)

        ( MealEntriesMsg mealEntryMsg, MealEntries mealEntry ) ->
            stepThrough steps.mealEntries model (Pages.MealEntries.Handler.update mealEntryMsg mealEntry)

        ( StatisticsMsg statisticsMsg, Statistics statistics ) ->
            stepThrough steps.statistics model (Pages.Statistics.Handler.update statisticsMsg statistics)

        ( ReferenceNutrientsMsg referenceNutrientsMsg, ReferenceNutrients referenceNutrients ) ->
            stepThrough steps.referenceNutrients model (Pages.ReferenceNutrients.Handler.update referenceNutrientsMsg referenceNutrients)

        _ ->
            ( model, Cmd.none )


stepTo : Url -> Model -> ( Model, Cmd Msg )
stepTo url model =
    case Parser.parse (routeParser model.jwt model.configuration) (fragmentToPath url) of
        Just answer ->
            case answer of
                LoginRoute flags ->
                    Pages.Login.Handler.init flags |> stepThrough steps.login model

                OverviewRoute flags ->
                    Pages.Overview.Handler.init flags |> stepThrough steps.overview model

                RecipesRoute flags ->
                    Pages.Recipes.Handler.init flags |> stepThrough steps.recipes model

                IngredientRoute flags ->
                    Pages.Ingredients.Handler.init flags |> stepThrough steps.ingredients model

                MealsRoute flags ->
                    Pages.Meals.Handler.init flags |> stepThrough steps.meals model

                MealEntriesRoute flags ->
                    Pages.MealEntries.Handler.init flags |> stepThrough steps.mealEntries model

                StatisticsRoute flags ->
                    Pages.Statistics.Handler.init flags |> stepThrough steps.statistics model

                ReferenceNutrientsRoute flags ->
                    Pages.ReferenceNutrients.Handler.init flags |> stepThrough steps.referenceNutrients model

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )


type alias StepParameters model msg =
    { page : model -> Page
    , message : msg -> Msg
    }


steps :
    { login : StepParameters Pages.Login.Page.Model Pages.Login.Page.Msg
    , overview : StepParameters Pages.Overview.Page.Model Pages.Overview.Page.Msg
    , recipes : StepParameters Pages.Recipes.Page.Model Pages.Recipes.Page.Msg
    , ingredients : StepParameters Pages.Ingredients.Page.Model Pages.Ingredients.Page.Msg
    , mealEntries : StepParameters Pages.MealEntries.Page.Model Pages.MealEntries.Page.Msg
    , meals : StepParameters Pages.Meals.Page.Model Pages.Meals.Page.Msg
    , statistics : StepParameters Pages.Statistics.Page.Model Pages.Statistics.Page.Msg
    , referenceNutrients : StepParameters Pages.ReferenceNutrients.Page.Model Pages.ReferenceNutrients.Page.Msg
    }
steps =
    { login = StepParameters Login LoginMsg
    , overview = StepParameters Overview OverviewMsg
    , recipes = StepParameters Recipes RecipesMsg
    , ingredients = StepParameters Ingredients IngredientsMsg
    , mealEntries = StepParameters MealEntries MealEntriesMsg
    , meals = StepParameters Meals MealsMsg
    , statistics = StepParameters Statistics StatisticsMsg
    , referenceNutrients = StepParameters ReferenceNutrients ReferenceNutrientsMsg
    }


stepThrough : { page : model -> Page, message : msg -> Msg } -> Model -> ( model, Cmd msg ) -> ( Model, Cmd Msg )
stepThrough ps model ( subModel, cmd ) =
    ( { model | page = ps.page subModel }, Cmd.map ps.message cmd )


type Route
    = LoginRoute Pages.Login.Page.Flags
    | OverviewRoute Pages.Overview.Page.Flags
    | RecipesRoute Pages.Recipes.Page.Flags
    | IngredientRoute Pages.Ingredients.Page.Flags
    | MealsRoute Pages.Meals.Page.Flags
    | MealEntriesRoute Pages.MealEntries.Page.Flags
    | StatisticsRoute Pages.Statistics.Page.Flags
    | ReferenceNutrientsRoute Pages.ReferenceNutrients.Page.Flags


routeParser : Maybe String -> Configuration -> Parser (Route -> a) a
routeParser jwt configuration =
    let
        loginParser =
            s "login" |> Parser.map { configuration = configuration }

        overviewParser =
            s "overview" |> Parser.map flags

        recipesParser =
            s "recipes" |> Parser.map flags

        ingredientParser =
            (s "ingredient-editor" </> ParserUtil.uuidParser)
                |> Parser.map
                    (\recipeId ->
                        { recipeId = recipeId
                        , configuration = configuration
                        , jwt = jwt
                        }
                    )

        mealsParser =
            s "meals" |> Parser.map flags

        mealEntriesParser =
            (s "meal-entry-editor" </> ParserUtil.uuidParser)
                |> Parser.map
                    (\mealId ->
                        { mealId = mealId
                        , configuration = configuration
                        , jwt = jwt
                        }
                    )

        statisticsParser =
            s "statistics" |> Parser.map flags

        referenceNutrientParser =
            s "reference-nutrients" |> Parser.map flags

        flags =
            { configuration = configuration, jwt = jwt }
    in
    Parser.oneOf
        [ route loginParser LoginRoute
        , route overviewParser OverviewRoute
        , route recipesParser RecipesRoute
        , route ingredientParser IngredientRoute
        , route mealsParser MealsRoute
        , route mealEntriesParser MealEntriesRoute
        , route statisticsParser StatisticsRoute
        , route referenceNutrientParser ReferenceNutrientsRoute
        ]


fragmentToPath : Url -> Url
fragmentToPath url =
    { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }


route : Parser a b -> a -> Parser (b -> c) c
route =
    flip Parser.map
