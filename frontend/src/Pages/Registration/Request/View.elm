module Pages.Registration.Request.View exposing (..)

import Basics.Extra exposing (flip)
import Html exposing (Html, button, div, input, label, text)
import Html.Attributes exposing (id)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Pages.Registration.Request.Page as Page
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput


view : Page.Model -> Html Page.Msg
view model =
    div [ Style.ids.request ]
        [ div []
            [ label [] [ text "Nickname" ]
            , input
                [ onInput
                    (flip (ValidatedInput.lift Page.lenses.nickname).set model >> Page.SetNickname)
                , onEnter Page.Request
                , Style.classes.editable
                ]
                []
            ]
        , div []
            [ label [] [ text "Email" ]
            , input
                [ onInput Page.SetEmail
                , onEnter Page.Request
                , Style.classes.editable
                ]
                []
            ]
        , div []
            [ button [ onClick Page.Request, Style.classes.button.confirm ] [ text "Log In" ] ]
        ]
