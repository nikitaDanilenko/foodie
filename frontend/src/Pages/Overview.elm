module Pages.Overview exposing (Flags, Model, Msg, init, update, updateToken, view)

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
    | UpdateToken String


updateToken : String -> Msg
updateToken =
    UpdateToken


type alias Flags =
    { configuration : Configuration
    , token : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { configuration = flags.configuration
      , token = flags.token
      }
    , doFetchToken ()
    )


view : Model -> Html Msg
view model =
    div [ id "overviewMain" ]
        [ div [ id "recipesButton" ]
            [ button [ class "button", onClick Recipes ] [ text "Recipes" ]
            ]
        , div [ id "projectsButton" ]
            [ button [ class "button", onClick Meals ] [ text "Meals" ] ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateToken t ->
            ( token.set t model, Cmd.none )

        _ ->
            let
                subFolder =
                    case msg of
                        Recipes ->
                            "recipes"

                        Meals ->
                            "meals"

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
