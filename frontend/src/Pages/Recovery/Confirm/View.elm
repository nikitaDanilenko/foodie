module Pages.Recovery.Confirm.View exposing (view)

import Basics.Extra exposing (flip)
import Html exposing (Html, button, div, input, label, table, tbody, td, text, tr)
import Html.Attributes exposing (disabled, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Pages.Recovery.Confirm.Page as Page
import Pages.Util.Links as Links
import Pages.Util.PasswordInput as PasswordInput
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate
import Util.MaybeUtil as MaybeUtil


view : Page.Model -> Html Page.Msg
view =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }


viewMain : Page.Main -> Html Page.LogicMsg
viewMain model =
    ViewUtil.viewMainWith
        { currentPage = Nothing
        , showNavigation = False
        }
    <|
        case model.mode of
            Page.Resetting ->
                viewResetting model

            Page.Confirmed ->
                viewConfirmed


viewResetting : Page.Main -> Html Page.LogicMsg
viewResetting model =
    let
        isValidPassword =
            PasswordInput.isValidPassword model.passwordInput

        enterAction =
            MaybeUtil.optional isValidPassword <| onEnter Page.Confirm
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
                                ([ MaybeUtil.defined <|
                                    onInput <|
                                        flip PasswordInput.lenses.password1.set
                                            model.passwordInput
                                            >> Page.SetPasswordInput
                                 , MaybeUtil.defined <| type_ "password"
                                 , MaybeUtil.defined <| value <| PasswordInput.lenses.password1.get <| model.passwordInput
                                 , MaybeUtil.defined <| Style.classes.editable
                                 , enterAction
                                 ]
                                    |> Maybe.Extra.values
                                )
                                []
                            ]
                        ]
                    , tr []
                        [ td [] [ label [] [ text "Password repetition" ] ]
                        , td []
                            [ input
                                ([ MaybeUtil.defined <|
                                    onInput <|
                                        flip PasswordInput.lenses.password2.set
                                            model.passwordInput
                                            >> Page.SetPasswordInput
                                 , MaybeUtil.defined <| type_ "password"
                                 , MaybeUtil.defined <| value <| PasswordInput.lenses.password2.get <| model.passwordInput
                                 , MaybeUtil.defined <| Style.classes.editable
                                 , enterAction
                                 ]
                                    |> Maybe.Extra.values
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


viewConfirmed : Html Page.LogicMsg
viewConfirmed =
    div [ Style.classes.confirm ]
        [ div [] [ label [] [ text "Successfully reset password." ] ]
        , div []
            [ Links.toLoginButton
                { buttonText = "Main page"
                }
            ]
        ]
