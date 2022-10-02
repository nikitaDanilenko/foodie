module Pages.Registration.Request.View exposing (..)

import Basics.Extra exposing (flip)
import Html exposing (Html, button, div, input, label, text)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Monocle.Lens exposing (Lens)
import Pages.Registration.Request.Page as Page
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput
import Util.LensUtil as LensUtil


view : Page.Model -> Html Page.Msg
view model =
    div [ Style.ids.request ]
        [ div []
            [ label [] [ text "Nickname" ]
            , input
                [ onInput
                    (flip (ValidatedInput.lift LensUtil.identityLens).set model.nickname
                        >> Page.SetNickname
                    )
                , onEnter Page.Request
                , Style.classes.editable
                ]
                []
            ]
        , div []
            [ label [] [ text "Email" ]
            , input
                [ onInput
                    (flip (ValidatedInput.lift LensUtil.identityLens).set model.email
                        >> Page.SetEmail
                    )
                , onEnter Page.Request
                , Style.classes.editable
                ]
                []
            ]
        , div []
            [ button [ onClick Page.Request, Style.classes.button.confirm ] [ text "Register" ] ]
        ]
