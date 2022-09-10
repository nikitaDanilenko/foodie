module Main exposing (main)

import Basics.Extra exposing (flip)
import Browser exposing (UrlRequest)
import Browser.Navigation as Nav
import Configuration exposing (Configuration)
import Html exposing (Html, div, text)
import Monocle.Lens exposing (Lens)
import Pages.IngredientEditor.Handler
import Pages.IngredientEditor.Page
import Pages.IngredientEditor.View
import Pages.Login.Handler
import Pages.Login.Page
import Pages.Login.View
import Pages.MealEntryEditor.Handler
import Pages.MealEntryEditor.Page
import Pages.MealEntryEditor.View
import Pages.Meals.Handler
import Pages.Meals.Page
import Pages.Meals.View
import Pages.Overview.Handler
import Pages.Overview.Page
import Pages.Overview.View
import Pages.Recipes.Handler
import Pages.Recipes.Page
import Pages.Recipes.View
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
    | IngredientEditor Pages.IngredientEditor.Page.Model
    | Meals Pages.Meals.Page.Model
    | MealEntryEditor Pages.MealEntryEditor.Page.Model
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
    | IngredientEditorMsg Pages.IngredientEditor.Page.Msg
    | MealsMsg Pages.Meals.Page.Msg
    | MealEntryEditorMsg Pages.MealEntryEditor.Page.Msg


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

        IngredientEditor ingredientEditor ->
            Html.map IngredientEditorMsg (Pages.IngredientEditor.View.view ingredientEditor)

        Meals meals ->
            Html.map MealsMsg (Pages.Meals.View.view meals)

        MealEntryEditor mealEntryEditor ->
            Html.map MealEntryEditorMsg (Pages.MealEntryEditor.View.view mealEntryEditor)

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

                IngredientEditor ingredientEditor ->
                    stepIngredientEditor model (Pages.IngredientEditor.Handler.update (Pages.IngredientEditor.Page.UpdateJWT token) ingredientEditor)

                Meals meals ->
                    stepMeals model (Pages.Meals.Handler.update (Pages.Meals.Page.UpdateJWT token) meals)

                MealEntryEditor mealEntryEditor ->
                    stepMealEntryEditor model (Pages.MealEntryEditor.Handler.update (Pages.MealEntryEditor.Page.UpdateJWT token) mealEntryEditor)

                NotFound ->
                    ( jwtLens.set (Just token) model, Cmd.none )

        ( FetchFoods foods, IngredientEditor ingredientEditor ) ->
            stepIngredientEditor model (Pages.IngredientEditor.Handler.update (Pages.IngredientEditor.Page.UpdateFoods foods) ingredientEditor)

        ( FetchMeasures measures, IngredientEditor ingredientEditor ) ->
            stepIngredientEditor model (Pages.IngredientEditor.Handler.update (Pages.IngredientEditor.Page.UpdateMeasures measures) ingredientEditor)

        ( OverviewMsg overviewMsg, Overview overview ) ->
            stepOverview model (Pages.Overview.Handler.update overviewMsg overview)

        ( RecipesMsg recipesMsg, Recipes recipes ) ->
            stepRecipes model (Pages.Recipes.Handler.update recipesMsg recipes)

        ( IngredientEditorMsg ingredientEditorMsg, IngredientEditor ingredientEditor ) ->
            stepIngredientEditor model (Pages.IngredientEditor.Handler.update ingredientEditorMsg ingredientEditor)

        ( MealsMsg mealsMsg, Meals meals ) ->
            stepMeals model (Pages.Meals.Handler.update mealsMsg meals)

        ( MealEntryEditorMsg mealEntryEditorMsg, MealEntryEditor mealEntryEditor ) ->
            stepMealEntryEditor model (Pages.MealEntryEditor.Handler.update mealEntryEditorMsg mealEntryEditor)

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

                IngredientEditorRoute flags ->
                    Pages.IngredientEditor.Handler.init flags |> stepIngredientEditor model

                MealsRoute flags ->
                    Pages.Meals.Handler.init flags |> stepMeals model

                MealEntryEditorRoute flags ->
                    Pages.MealEntryEditor.Handler.init flags |> stepMealEntryEditor model

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


stepIngredientEditor : Model -> ( Pages.IngredientEditor.Page.Model, Cmd Pages.IngredientEditor.Page.Msg ) -> ( Model, Cmd Msg )
stepIngredientEditor model ( ingredientEditor, cmd ) =
    ( { model | page = IngredientEditor ingredientEditor }, Cmd.map IngredientEditorMsg cmd )


stepMealEntryEditor : Model -> ( Pages.MealEntryEditor.Page.Model, Cmd Pages.MealEntryEditor.Page.Msg ) -> ( Model, Cmd Msg )
stepMealEntryEditor model ( mealEntryEditor, cmd ) =
    ( { model | page = MealEntryEditor mealEntryEditor }, Cmd.map MealEntryEditorMsg cmd )


stepMeals : Model -> ( Pages.Meals.Page.Model, Cmd Pages.Meals.Page.Msg ) -> ( Model, Cmd Msg )
stepMeals model ( recipes, cmd ) =
    ( { model | page = Meals recipes }, Cmd.map MealsMsg cmd )


type Route
    = LoginRoute Pages.Login.Page.Flags
    | OverviewRoute Pages.Overview.Page.Flags
    | RecipesRoute Pages.Recipes.Page.Flags
    | IngredientEditorRoute Pages.IngredientEditor.Page.Flags
    | MealsRoute Pages.Meals.Page.Flags
    | MealEntryEditorRoute Pages.MealEntryEditor.Page.Flags


routeParser : Maybe String -> Configuration -> Parser (Route -> a) a
routeParser jwt configuration =
    let
        loginParser =
            s "login" |> Parser.map { configuration = configuration }

        overviewParser =
            s "overview" |> Parser.map flags

        recipesParser =
            s "recipes" |> Parser.map flags

        ingredientEditorParser =
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

        mealEntryEditorParser =
            (s "meal-entry-editor" </> ParserUtil.uuidParser)
                |> Parser.map
                    (\mealId ->
                        { mealId = mealId
                        , configuration = configuration
                        , jwt = jwt
                        }
                    )

        flags =
            { configuration = configuration, jwt = jwt }
    in
    Parser.oneOf
        [ route loginParser LoginRoute
        , route overviewParser OverviewRoute
        , route recipesParser RecipesRoute
        , route ingredientEditorParser IngredientEditorRoute
        , route mealsParser MealsRoute
        , route mealEntryEditorParser MealEntryEditorRoute
        ]


fragmentToPath : Url -> Url
fragmentToPath url =
    { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }


route : Parser a b -> a -> Parser (b -> c) c
route =
    flip Parser.map
