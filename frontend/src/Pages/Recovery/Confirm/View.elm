module Pages.Recovery.Confirm.View exposing (view)

import Basics.Extra exposing (flip)
import Html exposing (Html, button, div, input, label, table, tbody, td, text, tr)
import Html.Attributes exposing (disabled, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Pages.Recovery.Confirm.Page as Page
import Pages.Util.Links as Links
import Pages.Util.PasswordInput as PasswordInput
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = always True
        , initialization = Page.lenses.initialization.get
        , configuration = .configuration
        , jwt = always Nothing
        , currentPage = Nothing
        , showNavigation = False
        }
        model
    <|
        case model.mode of
            Page.Resetting ->
                viewResetting model

            Page.Confirmed ->
                viewConfirmed model


viewResetting : Page.Model -> Html Page.Msg
viewResetting model =
    let
        isValidPassword =
            PasswordInput.isValidPassword model.passwordInput

        enterAction =
            if isValidPassword then
                [ onEnter Page.Confirm ]

            else
                []
    in
    div [ Style.classes.confirm ]
        [ div [] [ label [ Style.classes.info ] [ text "Account recovery" ] ]
        , div []
            [ table []
                [ tbody []
                    [ tr []
                        [ td [] [ label [] [ text "New password" ] ]
                        , td []
                            [ input
                                ([ onInput
                                    (flip PasswordInput.lenses.password1.set
                                        model.passwordInput
                                        >> Page.SetPasswordInput
                                    )
                                 , type_ "password"
                                 , value <| PasswordInput.lenses.password1.get <| model.passwordInput
                                 , Style.classes.editable
                                 ]
                                    ++ enterAction
                                )
                                []
                            ]
                        ]
                    , tr []
                        [ td [] [ label [] [ text "Password repetition" ] ]
                        , td []
                            [ input
                                ([ onInput
                                    (flip PasswordInput.lenses.password2.set
                                        model.passwordInput
                                        >> Page.SetPasswordInput
                                    )
                                 , type_ "password"
                                 , value <| PasswordInput.lenses.password2.get <| model.passwordInput
                                 , Style.classes.editable
                                 ]
                                    ++ enterAction
                                )
                                []
                            ]
                        ]
                    ]
                ]
            , div []
                [ button
                    [ onClick Page.Confirm
                    , Style.classes.button.confirm
                    , disabled <| not <| isValidPassword
                    ]
                    [ text "Reset password" ]
                ]
            ]
        ]


viewConfirmed : Page.Model -> Html Page.Msg
viewConfirmed model =
    div [ Style.classes.confirm ]
        [ div [] [ label [] [ text "Successfully reset password." ] ]
        , div []
            [ Links.toLoginButton
                { configuration = model.configuration
                , buttonText = "Main page"
                }
            ]
        ]
