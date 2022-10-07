module Pages.Registration.Confirm.View exposing (view)

import Basics.Extra exposing (flip)
import Html exposing (Html, button, div, input, label, table, tbody, td, text, tr)
import Html.Attributes exposing (disabled, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Pages.Registration.Confirm.Page as Page
import Pages.Util.ComplementInput as ComplementInput
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
            Page.Editing ->
                viewEditing model

            Page.Confirmed ->
                viewConfirmed model


viewEditing : Page.Model -> Html Page.Msg
viewEditing model =
    let
        isValid =
            PasswordInput.isValidPassword model.complementInput.passwordInput

        enterAction =
            if isValid then
                [ onEnter Page.Request ]

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
        [ div [] [ label [ Style.classes.info ] [ text "Confirm registration" ] ]
        , table []
            [ tbody []
                [ tr []
                    [ td [] [ label [] [ text "Nickname" ] ]
                    , td [] [ label [] [ text <| model.userIdentifier.nickname ] ]
                    ]
                , tr []
                    [ td [] [ label [] [ text "Email" ] ]
                    , td [] [ label [] [ text <| model.userIdentifier.email ] ]
                    ]
                , tr []
                    [ td [] [ label [] [ text "Display name (optional)" ] ]
                    , td []
                        [ input
                            ([ onInput
                                (Just
                                    >> Maybe.Extra.filter (String.isEmpty >> not)
                                    >> (flip ComplementInput.lenses.displayName.set
                                            model.complementInput
                                            >> Page.SetComplementInput
                                       )
                                )
                             , Style.classes.editable
                             ]
                                ++ enterAction
                            )
                            []
                        ]
                    ]
                , tr []
                    [ td [] [ label [] [ text "Password" ] ]
                    , td []
                        [ input
                            ([ onInput
                                (flip password1Lens.set
                                    model.complementInput
                                    >> Page.SetComplementInput
                                )
                             , value <| password1Lens.get <| model.complementInput
                             , type_ "password"
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
                                (flip password2Lens.set
                                    model.complementInput
                                    >> Page.SetComplementInput
                                )
                             , value <| password2Lens.get <| model.complementInput
                             , type_ "password"
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
                [ onClick Page.Request
                , Style.classes.button.confirm
                , disabled <| not <| isValid
                ]
                [ text "Confirm" ]
            ]
        ]


viewConfirmed : Page.Model -> Html Page.Msg
viewConfirmed model =
    div [ Style.classes.confirm ]
        [ div [] [ label [] [ text "User creation successful." ] ]
        , div []
            [ Links.toLoginButton
                { configuration = model.configuration
                , buttonText = "Main page"
                }
            ]
        ]
