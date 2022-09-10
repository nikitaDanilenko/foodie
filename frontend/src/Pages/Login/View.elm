module Pages.Login.View exposing (..)

import Html exposing (Html, button, div, input, label, text)
import Html.Attributes exposing (autocomplete, class, for, id, type_)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Pages.Login.Page as Page


view : Page.Model -> Html Page.Msg
view _ =
    div [ id "initialMain" ]
        [ div [ id "userField" ]
            [ label [ for "user" ] [ text "Nickname" ]
            , input [ autocomplete True, onInput Page.SetNickname, onEnter Page.Login ] []
            ]
        , div [ id "passwordField" ]
            [ label [ for "password" ] [ text "Password" ]
            , input [ type_ "password", autocomplete True, onInput Page.SetPassword, onEnter Page.Login ] []
            ]
        , div [ id "fetchButton" ]
            [ button [ class "button", onClick Page.Login ] [ text "Log In" ] ]
        ]
