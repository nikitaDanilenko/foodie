module Pages.Login.View exposing (..)

import Html exposing (Html, button, div, input, label, text)
import Html.Attributes exposing (autocomplete, type_)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Pages.Login.Page as Page
import Pages.Util.Style as Style


view : Page.Model -> Html Page.Msg
view _ =
    div [ Style.ids.login ]
        [ div []
            [ label [ ] [ text "Nickname" ]
            , input
                [ autocomplete True
                , onInput Page.SetNickname
                , onEnter Page.Login
                , Style.classes.editable
                ]
                []
            ]
        , div []
            [ label [] [ text "Password" ]
            , input
                [ type_ "password"
                , autocomplete True
                , onInput Page.SetPassword
                , onEnter Page.Login
                , Style.classes.editable
                ]
                []
            ]
        , div []
            [ button [ onClick Page.Login, Style.classes.button.confirm ] [ text "Log In" ] ]
        ]
