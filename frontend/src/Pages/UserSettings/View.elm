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
import Pages.UserSettings.Status as Status
import Pages.Util.ComplementInput as ComplementInput
import Pages.Util.PasswordInput as PasswordInput
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil exposing (Page(..))


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = Page.lenses.initialization.get
        , configuration = .flagsWithJWT >> .configuration
        , jwt = .flagsWithJWT >> .jwt >> Just
        , currentPage = Just (UserSettings model.user.nickname)
        , showNavigation = True
        }
        model
    <|
        case model.mode of
            Page.Regular ->
                viewRegular model

            Page.RequestedDeletion ->
                viewRequestedDeletion model


viewRegular : Page.Model -> Html Page.Msg
viewRegular model =
    let
        isValidPassword =
            PasswordInput.isValidPassword model.complementInput.passwordInput

        enterPasswordAction =
            if isValidPassword then
                [ onEnter Page.UpdatePassword ]

            else
                []

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
                        , td [] [ label [] [ text <| model.user.nickname ] ]
                        ]
                    , tr []
                        [ td [] [ label [] [ text "Email" ] ]
                        , td [] [ label [] [ text <| model.user.email ] ]
                        ]
                    , tr []
                        [ td [] [ label [] [ text "Display name" ] ]
                        , td [] [ label [] [ text <| Maybe.withDefault "" <| model.user.displayName ] ]
                        ]
                    , tr []
                        [ td [] [ label [] [ text "New display name" ] ]
                        , td []
                            [ input
                                [ onInput
                                    (Just
                                        >> Maybe.Extra.filter (String.isEmpty >> not)
                                        >> (flip ComplementInput.lenses.displayName.set
                                                model.complementInput
                                                >> Page.SetComplementInput
                                           )
                                    )
                                , value <| Maybe.withDefault "" <| model.complementInput.displayName
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
                                ([ onInput
                                    (flip password1Lens.set
                                        model.complementInput
                                        >> Page.SetComplementInput
                                    )
                                 , type_ "password"
                                 , value <| password1Lens.get <| model.complementInput
                                 , Style.classes.editable
                                 ]
                                    ++ enterPasswordAction
                                )
                                []
                            ]
                        ]
                    , tr []
                        [ td [] [ label [] [ text "Password repetition" ] ]
                        , td []
                            [ input
                                ([ onInput
                                    (flip password2Lens.set
                                        model.complementInput
                                        >> Page.SetComplementInput
                                    )
                                 , type_ "password"
                                 , value <| password2Lens.get <| model.complementInput
                                 , Style.classes.editable
                                 ]
                                    ++ enterPasswordAction
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


viewRequestedDeletion : Page.Model -> Html Page.Msg
viewRequestedDeletion _ =
    div [ Style.classes.confirm ]
        [ div [] [ label [] [ text "Account deletion requested. Please check your email to continue." ] ]
        ]
