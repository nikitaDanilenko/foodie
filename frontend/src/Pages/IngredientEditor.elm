module Pages.IngredientEditor exposing (..)

import Api.Auxiliary exposing (IngredientId)
import Api.Types.Ingredient exposing (Ingredient)
import Api.Types.IngredientUpdate exposing (IngredientUpdate)
import Configuration exposing (Configuration)
import Either exposing (Either)
import Html exposing (Html, button, div, label, td, text, thead, tr)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Http exposing (Error)
import Monocle.Lens exposing (Lens)
import Ports exposing (doFetchToken)
import Util.Editing exposing (Editing)


type alias Model =
    { configuration : Configuration
    , jwt : String
    , ingredients : List (Either Ingredient (Editing Ingredient IngredientUpdate))
    }


jwtLens : Lens Model String
jwtLens =
    Lens .jwt (\b a -> { a | jwt = b })


ingredientsLens : Lens Model (List (Either Ingredient (Editing Ingredient IngredientUpdate)))
ingredientsLens =
    Lens .ingredients (\b a -> { a | ingredients = b })


type Msg
    = AddIngredient
    | GotAddIngredientResponse (Result Error Ingredient)
    | UpdateIngredient IngredientId IngredientUpdate
    | SaveIngredientEdit IngredientId
    | GotSaveIngredientResponse IngredientId (Result Error Ingredient)
    | EnterEditIngredient IngredientId
    | ExitEditIngredientAt IngredientId
    | DeleteIngredient IngredientId
    | GotDeleteIngredientResponse IngredientId (Result Error ())
    | GotFetchIngredientsResponse (Result Error (List Ingredient))
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
    let
        ( jwt, cmd ) =
            case flags.jwt of
                Just token ->
                    ( token, fetchIngredients flags.configuration token )

                Nothing ->
                    ( "", doFetchToken () )
    in
    ( { configuration = flags.configuration
      , jwt = jwt
      , ingredients = []
      }
    , cmd
    )


view : Model -> Html Msg
view model =
    let
        viewEditIngredients =
            List.map
                (Either.unpack
                    (editOrDeleteIngredientLine model.configuration)
                    (\e -> e.update |> editIngredientLine e.original.id)
                )
    in
    div [ id "addIngredientView" ]
        (div [ id "addIngredient" ] [ button [ class "button", onClick AddIngredient ] [ text "Add ingredient" ] ]
            :: thead []
                [ tr []
                    [ td [] [ label [] [ text "Name" ] ]
                    , td [] [ label [] [ text "Description" ] ]
                    ]
                ]
            :: viewEditIngredients model.ingredients
        )
