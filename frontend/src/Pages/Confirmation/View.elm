module Pages.Confirmation.View exposing (view)

import Html exposing (Html, button, div, label, text)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Pages.Confirmation.Page as Page


view : Page.Model -> Html Page.Msg
view _ =
    div [ id "confirmation" ]
        [ div [ class "info" ]
            [ label [] [ text "Please check your email. Follow the suggested instructions to continue." ]
            ]
        , div [ class "navigation" ]
            [ button [ onClick Page.NavigateToMain ] [ text "Main page" ] ]
        ]
