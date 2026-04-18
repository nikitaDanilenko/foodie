module Pages.UserSettings.View exposing (view)

import Api.Types.Mode exposing (Mode(..))
import Basics.Extra exposing (flip)
import Html exposing (Html, button, div, input, label, table, tbody, td, text, tr)
import Html.Attributes exposing (disabled, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Pages.UserSettings.Page as Page
import Pages.Util.ComplementInput as ComplementInput
import Pages.Util.PasswordInput as PasswordInput
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil exposing (Page(..))
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
        { currentPage = Just UserSettings
        , showNavigation = True
        }
    <|
        case model.mode of
            Page.Regular ->
                viewRegular model

            Page.RequestedDeletion ->
                viewRequestedDeletion model


viewRegular : Page.Main -> Html Page.LogicMsg
viewRegular main =
    let
        isValidPassword =
            PasswordInput.isValidPassword main.complementInput.passwordInput

        enterPasswordAction =
            MaybeUtil.optional isValidPassword <| onEnter Page.UpdatePassword

        password1Lens =
            ComplementInput.lenses.passwordInput
                |> Compose.lensWithLens PasswordInput.lenses.password1

        password2Lens =
            ComplementInput.lenses.passwordInput
                |> Compose.lensWithLens PasswordInput.lenses.password2
    in
    div [ Style.classes.confirm ]
        [ div [] [ label [ Style.classes.info ] [ text "User settings" ] ]
        , div []
            [ table []
                [ tbody []
                    [ tr []
                        [ td [] [ label [] [ text "Nickname" ] ]
                        , td [] [ label [] [ text <| .nickname <| main.user ] ]
                        ]
                    , tr []
                        [ td [] [ label [] [ text "Email" ] ]
                        , td [] [ label [] [ text <| .email <| main.user ] ]
                        ]
                    , tr []
                        [ td [] [ label [] [ text "Display name" ] ]
                        , td [] [ label [] [ text <| Maybe.withDefault "" <| .displayName <| main.user ] ]
                        ]
                    , tr []
                        [ td [] [ label [] [ text "New display name" ] ]
                        , td []
                            [ input
                                [ onInput
                                    (Just
                                        >> Maybe.Extra.filter (String.isEmpty >> not)
                                        >> (flip ComplementInput.lenses.displayName.set
                                                main.complementInput
                                                >> Page.SetComplementInput
                                           )
                                    )
                                , value <| Maybe.withDefault "" <| main.complementInput.displayName
                                , Style.classes.editable
                                , onEnter Page.UpdateSettings
                                ]
                                []
                            ]
                        ]
                    ]
                ]
            , div []
                [ button
                    [ onClick Page.UpdateSettings
                    , Style.classes.button.confirm
                    ]
                    [ text "Update settings" ]
                ]
            ]
        , div []
            [ table []
                [ tbody []
                    [ tr []
                        [ td [] [ label [] [ text "New password" ] ]
                        , td []
                            [ input
                                ([ MaybeUtil.defined <|
                                    onInput <|
                                        flip password1Lens.set
                                            main.complementInput
                                            >> Page.SetComplementInput
                                 , MaybeUtil.defined <| type_ "password"
                                 , MaybeUtil.defined <| value <| password1Lens.get <| main.complementInput
                                 , MaybeUtil.defined <| Style.classes.editable
                                 , enterPasswordAction
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
                                        flip password2Lens.set
                                            main.complementInput
                                            >> Page.SetComplementInput
                                 , MaybeUtil.defined <| type_ "password"
                                 , MaybeUtil.defined <| value <| password2Lens.get <| main.complementInput
                                 , MaybeUtil.defined <| Style.classes.editable
                                 , enterPasswordAction
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
                    [ onClick Page.UpdatePassword
                    , Style.classes.button.confirm
                    , disabled <| not <| isValidPassword
                    ]
                    [ text "Update password" ]
                ]
            ]
        , div []
            [ button
                [ onClick Page.RequestDeletion
                , Style.classes.button.delete
                ]
                [ text "Delete account" ]
            ]
        , div []
            [ button
                [ onClick (Page.Logout Api.Types.Mode.This)
                , Style.classes.button.logout
                ]
                [ text "Logout this device" ]
            ]
        , div []
            [ button
                [ onClick (Page.Logout Api.Types.Mode.All)
                , Style.classes.button.logout
                ]
                [ text "Logout all devices" ]
            ]
        ]


viewRequestedDeletion : Page.Main -> Html Page.LogicMsg
viewRequestedDeletion _ =
    div [ Style.classes.confirm ]
        [ div [] [ label [] [ text "Account deletion requested. Please check your email to continue." ] ]
        ]
