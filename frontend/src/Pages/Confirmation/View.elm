module Pages.Confirmation.View exposing (view)

import Html exposing (Html, button, div, label, text)
import Html.Events exposing (onClick)
import Pages.Confirmation.Page as Page
import Pages.Util.Style as Style


view : Page.Model -> Html Page.Msg
view _ =
    div [ Style.classes.confirm ]
        [ div [ Style.classes.info ]
            [ label [] [ text "Please check your email. Follow the suggested instructions to continue." ]
            ]
        , div [ Style.classes.button.navigation ]
            [ button [ onClick Page.NavigateToMain ] [ text "Main page" ] ]
        ]
