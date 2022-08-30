module Main exposing (main)

import Basics.Extra exposing (flip)
import Browser exposing (UrlRequest)
import Browser.Navigation as Nav
import Configuration exposing (Configuration)
import Html exposing (Html, div, text)
import Pages.Login as Login
import Pages.Overview as Overview
import Ports exposing (doFetchToken, fetchToken)
import Url exposing (Url)
import Url.Parser as Parser exposing (Parser, s)


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
    fetchToken FetchToken


type alias Model =
    { key : Nav.Key
    , page : Page
    , configuration : Configuration
    }


type Page
    = Login Login.Model
    | Overview Overview.Model
    | NotFound


type Msg
    = ClickedLink UrlRequest
    | ChangedUrl Url
    | FetchToken String
    | LoginMsg Login.Msg
    | OverviewMsg Overview.Msg


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
                    ( model, Cmd.none )

                Overview overview ->
                    stepOverview model (Overview.update (Overview.updateToken token) overview)

                NotFound ->
                    ( model, Cmd.none )

        ( OverviewMsg overviewMsg, Overview overview ) ->
            stepOverview model (Overview.update overviewMsg overview)

        _ ->
            ( model, Cmd.none )


stepTo : Url -> Model -> ( Model, Cmd Msg )
stepTo url model =
    case Parser.parse (routeParser model.configuration) (fragmentToPath url) of
        Just answer ->
            case answer of
                LoginRoute flags ->
                    Login.init flags |> stepLogin model

                OverviewRoute flags ->
                    Overview.init flags |> stepOverview model

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )


stepLogin : Model -> ( Login.Model, Cmd Login.Msg ) -> ( Model, Cmd Msg )
stepLogin model ( login, cmd ) =
    ( { model | page = Login login }, Cmd.map LoginMsg cmd )


stepOverview : Model -> ( Overview.Model, Cmd Overview.Msg ) -> ( Model, Cmd Msg )
stepOverview model ( overview, cmd ) =
    ( { model | page = Overview overview }, Cmd.map OverviewMsg cmd )


type Route
    = LoginRoute Login.Flags
    | OverviewRoute Overview.Flags


routeParser : Configuration -> Parser (Route -> a) a
routeParser configuration =
    let
        loginParser =
            s "login"

        overviewParser =
            s "overview"
    in
    Parser.oneOf
        [ route loginParser (LoginRoute { configuration = configuration })
        , route overviewParser (OverviewRoute { configuration = configuration, token = "" })
        ]


fragmentToPath : Url -> Url
fragmentToPath url =
    { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }


route : Parser a b -> a -> Parser (b -> c) c
route =
    flip Parser.map
