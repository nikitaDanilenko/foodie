module Main exposing (main)

import Basics.Extra exposing (flip)
import Browser exposing (UrlRequest)
import Browser.Navigation as Nav
import Configuration exposing (Configuration)
import Html exposing (Html, div, text)
import Monocle.Lens exposing (Lens)
import Pages.Ingredient.Handler
import Pages.Ingredient.Page
import Pages.Ingredient.View
import Pages.Login.Handler
import Pages.Login.Page
import Pages.Login.View
import Pages.MealEntry.Handler
import Pages.MealEntry.Page
import Pages.MealEntry.View
import Pages.Meals.Handler
import Pages.Meals.Page
import Pages.Meals.View
import Pages.Overview.Handler
import Pages.Overview.Page
import Pages.Overview.View
import Pages.Recipes.Handler
import Pages.Recipes.Page
import Pages.Recipes.View
import Pages.Statistics.Handler
import Pages.Statistics.Page
import Pages.Statistics.View
import Pages.Util.ParserUtil as ParserUtil
import Ports exposing (doFetchToken, fetchFoods, fetchMeasures, fetchToken)
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
    | Ingredient Pages.Ingredient.Page.Model
    | Meals Pages.Meals.Page.Model
    | MealEntry Pages.MealEntry.Page.Model
    | Statistics Pages.Statistics.Page.Model
    | NotFound


type Msg
    = ClickedLink UrlRequest
    | ChangedUrl Url
    | FetchToken String
    | FetchFoods String
    | FetchMeasures String
    | LoginMsg Pages.Login.Page.Msg
    | OverviewMsg Pages.Overview.Page.Msg
    | RecipesMsg Pages.Recipes.Page.Msg
    | IngredientMsg Pages.Ingredient.Page.Msg
    | MealsMsg Pages.Meals.Page.Msg
    | MealEntryMsg Pages.MealEntry.Page.Msg
    | StatisticsMsg Pages.Statistics.Page.Msg


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

        Ingredient ingredient ->
            Html.map IngredientMsg (Pages.Ingredient.View.view ingredient)

        Meals meals ->
            Html.map MealsMsg (Pages.Meals.View.view meals)

        MealEntry mealEntry ->
            Html.map MealEntryMsg (Pages.MealEntry.View.view mealEntry)

        Statistics statistics ->
            Html.map StatisticsMsg (Pages.Statistics.View.view statistics)

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
            stepLogin model (Pages.Login.Handler.update loginMsg login)

        -- todo: Check all cases, and possibly refactor to have less duplication.
        ( FetchToken token, page ) ->
            case page of
                Login _ ->
                    ( jwtLens.set (Just token) model, Cmd.none )

                Overview overview ->
                    stepOverview model (Pages.Overview.Handler.update (Pages.Overview.Page.UpdateJWT token) overview)

                Recipes recipes ->
                    stepRecipes model (Pages.Recipes.Handler.update (Pages.Recipes.Page.UpdateJWT token) recipes)

                Ingredient ingredient ->
                    stepIngredient model (Pages.Ingredient.Handler.update (Pages.Ingredient.Page.UpdateJWT token) ingredient)

                Meals meals ->
                    stepMeals model (Pages.Meals.Handler.update (Pages.Meals.Page.UpdateJWT token) meals)

                MealEntry mealEntry ->
                    stepMealEntry model (Pages.MealEntry.Handler.update (Pages.MealEntry.Page.UpdateJWT token) mealEntry)

                Statistics statistics ->
                    stepStatistics model (Pages.Statistics.Handler.update (Pages.Statistics.Page.UpdateJWT token) statistics)

                NotFound ->
                    ( jwtLens.set (Just token) model, Cmd.none )

        ( FetchFoods foods, Ingredient ingredient ) ->
            stepIngredient model (Pages.Ingredient.Handler.update (Pages.Ingredient.Page.UpdateFoods foods) ingredient)

        ( FetchMeasures measures, Ingredient ingredient ) ->
            stepIngredient model (Pages.Ingredient.Handler.update (Pages.Ingredient.Page.UpdateMeasures measures) ingredient)

        ( OverviewMsg overviewMsg, Overview overview ) ->
            stepOverview model (Pages.Overview.Handler.update overviewMsg overview)

        ( RecipesMsg recipesMsg, Recipes recipes ) ->
            stepRecipes model (Pages.Recipes.Handler.update recipesMsg recipes)

        ( IngredientMsg ingredientMsg, Ingredient ingredient ) ->
            stepIngredient model (Pages.Ingredient.Handler.update ingredientMsg ingredient)

        ( MealsMsg mealsMsg, Meals meals ) ->
            stepMeals model (Pages.Meals.Handler.update mealsMsg meals)

        ( MealEntryMsg mealEntryMsg, MealEntry mealEntry ) ->
            stepMealEntry model (Pages.MealEntry.Handler.update mealEntryMsg mealEntry)

        ( StatisticsMsg statisticsMsg, Statistics statistics ) ->
            stepStatistics model (Pages.Statistics.Handler.update statisticsMsg statistics)

        _ ->
            ( model, Cmd.none )


stepTo : Url -> Model -> ( Model, Cmd Msg )
stepTo url model =
    case Parser.parse (routeParser model.jwt model.configuration) (fragmentToPath url) of
        Just answer ->
            case answer of
                LoginRoute flags ->
                    Pages.Login.Handler.init flags |> stepLogin model

                OverviewRoute flags ->
                    Pages.Overview.Handler.init flags |> stepOverview model

                RecipesRoute flags ->
                    Pages.Recipes.Handler.init flags |> stepRecipes model

                IngredientRoute flags ->
                    Pages.Ingredient.Handler.init flags |> stepIngredient model

                MealsRoute flags ->
                    Pages.Meals.Handler.init flags |> stepMeals model

                MealEntryRoute flags ->
                    Pages.MealEntry.Handler.init flags |> stepMealEntry model

                StatisticsRoute flags ->
                    Pages.Statistics.Handler.init flags |> stepStatistics model

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )


stepLogin : Model -> ( Pages.Login.Page.Model, Cmd Pages.Login.Page.Msg ) -> ( Model, Cmd Msg )
stepLogin model ( login, cmd ) =
    ( { model | page = Login login }, Cmd.map LoginMsg cmd )


stepOverview : Model -> ( Pages.Overview.Page.Model, Cmd Pages.Overview.Page.Msg ) -> ( Model, Cmd Msg )
stepOverview model ( overview, cmd ) =
    ( { model | page = Overview overview }, Cmd.map OverviewMsg cmd )


stepRecipes : Model -> ( Pages.Recipes.Page.Model, Cmd Pages.Recipes.Page.Msg ) -> ( Model, Cmd Msg )
stepRecipes model ( recipes, cmd ) =
    ( { model | page = Recipes recipes }, Cmd.map RecipesMsg cmd )


stepIngredient : Model -> ( Pages.Ingredient.Page.Model, Cmd Pages.Ingredient.Page.Msg ) -> ( Model, Cmd Msg )
stepIngredient model ( ingredient, cmd ) =
    ( { model | page = Ingredient ingredient }, Cmd.map IngredientMsg cmd )


stepMealEntry : Model -> ( Pages.MealEntry.Page.Model, Cmd Pages.MealEntry.Page.Msg ) -> ( Model, Cmd Msg )
stepMealEntry model ( mealEntry, cmd ) =
    ( { model | page = MealEntry mealEntry }, Cmd.map MealEntryMsg cmd )


stepMeals : Model -> ( Pages.Meals.Page.Model, Cmd Pages.Meals.Page.Msg ) -> ( Model, Cmd Msg )
stepMeals model ( recipes, cmd ) =
    ( { model | page = Meals recipes }, Cmd.map MealsMsg cmd )


stepStatistics : Model -> ( Pages.Statistics.Page.Model, Cmd Pages.Statistics.Page.Msg ) -> ( Model, Cmd Msg )
stepStatistics model ( statistics, cmd ) =
    ( { model | page = Statistics statistics }, Cmd.map StatisticsMsg cmd )


type Route
    = LoginRoute Pages.Login.Page.Flags
    | OverviewRoute Pages.Overview.Page.Flags
    | RecipesRoute Pages.Recipes.Page.Flags
    | IngredientRoute Pages.Ingredient.Page.Flags
    | MealsRoute Pages.Meals.Page.Flags
    | MealEntryRoute Pages.MealEntry.Page.Flags
    | StatisticsRoute Pages.Statistics.Page.Flags


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

        mealEntryParser =
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

        flags =
            { configuration = configuration, jwt = jwt }
    in
    Parser.oneOf
        [ route loginParser LoginRoute
        , route overviewParser OverviewRoute
        , route recipesParser RecipesRoute
        , route ingredientParser IngredientRoute
        , route mealsParser MealsRoute
        , route mealEntryParser MealEntryRoute
        , route statisticsParser StatisticsRoute
        ]


fragmentToPath : Url -> Url
fragmentToPath url =
    { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }


route : Parser a b -> a -> Parser (b -> c) c
route =
    flip Parser.map
