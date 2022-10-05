module Pages.UserSettings.View exposing (view)

import Api.Types.Mode exposing (Mode(..))
import Basics.Extra exposing (flip)
import Html exposing (Html, button, div, input, label, table, tbody, td, text, tr)
import Html.Attributes exposing (disabled, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Pages.UserSettings.Page as Page
import Pages.UserSettings.Status as Status
import Pages.Util.ComplementInput as ComplementInput
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
        let
            isValidPassword =
                ComplementInput.isValidPassword model.complementInput

            enterAction =
                if isValidPassword then
                    [ onEnter Page.UpdateSettings ]

                else
                    []
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
                                        (flip ComplementInput.lenses.password1.set
                                            model.complementInput
                                            >> Page.SetComplementInput
                                        )
                                     , type_ "password"
                                     , value <| model.complementInput.password1
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
                                        (flip ComplementInput.lenses.password2.set
                                            model.complementInput
                                            >> Page.SetComplementInput
                                        )
                                     , type_ "password"
                                     , value <| model.complementInput.password2
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
                    [ onClick (Page.Logout This)
                    , Style.classes.button.logout
                    ]
                    [ text "Logout this device" ]
                ]
            , div []
                [ button
                    [ onClick (Page.Logout All)
                    , Style.classes.button.logout
                    ]
                    [ text "Logout all devices" ]
                ]
            ]
