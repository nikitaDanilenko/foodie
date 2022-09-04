module Main exposing (main)

import Basics.Extra exposing (flip)
import Browser exposing (UrlRequest)
import Browser.Navigation as Nav
import Configuration exposing (Configuration)
import Html exposing (Html, div, text)
import Monocle.Lens exposing (Lens)
import Pages.IngredientEditor.IngredientEditor as IngredientEditor
import Pages.Login as Login
import Pages.Overview as Overview
import Pages.Recipes as Recipes
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
    = Login Login.Model
    | Overview Overview.Model
    | Recipes Recipes.Model
    | IngredientEditor IngredientEditor.Model
    | NotFound


type Msg
    = ClickedLink UrlRequest
    | ChangedUrl Url
    | FetchToken String
    | FetchFoods String
    | FetchMeasures String
    | LoginMsg Login.Msg
    | OverviewMsg Overview.Msg
    | RecipesMsg Recipes.Msg
    | IngredientEditorMsg IngredientEditor.Msg


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
            Html.map LoginMsg (Login.view login)

        Overview overview ->
            Html.map OverviewMsg (Overview.view overview)

        Recipes recipes ->
            Html.map RecipesMsg (Recipes.view recipes)

        IngredientEditor ingredientEditor ->
            Html.map IngredientEditorMsg (IngredientEditor.view ingredientEditor)

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
            stepLogin model (Login.update loginMsg login)

        -- todo: Check all cases, and possibly refactor to have less duplication.
        ( FetchToken token, page ) ->
            case page of
                Login _ ->
                    ( jwtLens.set (Just token) model, Cmd.none )

                Overview overview ->
                    stepOverview model (Overview.update (Overview.updateJWT token) overview)

                Recipes recipes ->
                    stepRecipes model (Recipes.update (Recipes.updateJWT token) recipes)

                IngredientEditor ingredientEditor ->
                    stepIngredientEditor model (IngredientEditor.update (IngredientEditor.updateJWT token) ingredientEditor)

                NotFound ->
                    ( jwtLens.set (Just token) model, Cmd.none )

        ( FetchFoods foods, IngredientEditor ingredientEditor ) ->
            stepIngredientEditor model (IngredientEditor.update (IngredientEditor.updateFoods foods) ingredientEditor)

        ( FetchMeasures measures, IngredientEditor ingredientEditor ) ->
            stepIngredientEditor model (IngredientEditor.update (IngredientEditor.updateMeasures measures) ingredientEditor)

        ( OverviewMsg overviewMsg, Overview overview ) ->
            stepOverview model (Overview.update overviewMsg overview)

        ( RecipesMsg recipesMsg, Recipes recipes ) ->
            stepRecipes model (Recipes.update recipesMsg recipes)

        ( IngredientEditorMsg ingredientEditorMsg, IngredientEditor ingredientEditor ) ->
            stepIngredientEditor model (IngredientEditor.update ingredientEditorMsg ingredientEditor)

        _ ->
            ( model, Cmd.none )


stepTo : Url -> Model -> ( Model, Cmd Msg )
stepTo url model =
    case Parser.parse (routeParser model.jwt model.configuration) (fragmentToPath url) of
        Just answer ->
            case answer of
                LoginRoute flags ->
                    Login.init flags |> stepLogin model

                OverviewRoute flags ->
                    Overview.init flags |> stepOverview model

                RecipesRoute flags ->
                    Recipes.init flags |> stepRecipes model

                IngredientEditorRoute flags ->
                    IngredientEditor.init flags |> stepIngredientEditor model

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )


stepLogin : Model -> ( Login.Model, Cmd Login.Msg ) -> ( Model, Cmd Msg )
stepLogin model ( login, cmd ) =
    ( { model | page = Login login }, Cmd.map LoginMsg cmd )


stepOverview : Model -> ( Overview.Model, Cmd Overview.Msg ) -> ( Model, Cmd Msg )
stepOverview model ( overview, cmd ) =
    ( { model | page = Overview overview }, Cmd.map OverviewMsg cmd )


stepRecipes : Model -> ( Recipes.Model, Cmd Recipes.Msg ) -> ( Model, Cmd Msg )
stepRecipes model ( recipes, cmd ) =
    ( { model | page = Recipes recipes }, Cmd.map RecipesMsg cmd )


stepIngredientEditor : Model -> ( IngredientEditor.Model, Cmd IngredientEditor.Msg ) -> ( Model, Cmd Msg )
stepIngredientEditor model ( ingredientEditor, cmd ) =
    ( { model | page = IngredientEditor ingredientEditor }, Cmd.map IngredientEditorMsg cmd )


type Route
    = LoginRoute Login.Flags
    | OverviewRoute Overview.Flags
    | RecipesRoute Recipes.Flags
    | IngredientEditorRoute IngredientEditor.Flags


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

        flags =
            { configuration = configuration, jwt = jwt }
    in
    Parser.oneOf
        [ route loginParser LoginRoute
        , route overviewParser OverviewRoute
        , route recipesParser RecipesRoute
        , route ingredientEditorParser IngredientEditorRoute
        ]


fragmentToPath : Url -> Url
fragmentToPath url =
    { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }


route : Parser a b -> a -> Parser (b -> c) c
route =
    flip Parser.map
