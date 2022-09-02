module Pages.Overview exposing (Flags, Model, Msg, init, update, updateJWT, view)

import Browser.Navigation as Navigation
import Configuration exposing (Configuration)
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Monocle.Lens exposing (Lens)
import Ports exposing (doFetchToken)
import Url.Builder as UrlBuilder


type alias Model =
    { configuration : Configuration
    , token : String
    }


token : Lens Model String
token =
    Lens .token (\b a -> { a | token = b })


type Msg
    = Recipes
    | Meals
    | Statistics
    | UpdateJWT String


updateJWT : String -> Msg
updateJWT =
    UpdateJWT


type alias Flags =
    { configuration : Configuration
    , jwt : Maybe String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    case flags.jwt of
        Just jwt ->
            ( { configuration = flags.configuration
              , token = jwt
              }
            , Cmd.none
            )

        Nothing ->
            ( { configuration = flags.configuration
              , token = ""
              }
            , doFetchToken ()
            )


view : Model -> Html Msg
view _ =
    div [ id "overviewMain" ]
        [ div [ id "recipesButton" ]
            [ button [ class "button", onClick Recipes ] [ text "Recipes" ] ]
        , div [ id "mealsButton" ]
            [ button [ class "button", onClick Meals ] [ text "Meals" ] ]
        , div [ id "statsButton" ]
            [ button [ class "button", onClick Statistics ] [ text "Statistics" ] ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateJWT t ->
            ( token.set t model, Cmd.none )

        _ ->
            let
                subFolder =
                    case msg of
                        Recipes ->
                            "recipes"

                        Meals ->
                            "meals"

                        Statistics ->
                            "statistics"

                        _ ->
                            ""

                link =
                    UrlBuilder.relative
                        [ model.configuration.mainPageURL
                        , "#"
                        , subFolder
                        ]
                        []
            in
            ( model, Navigation.load link )
