module Pages.Registration.Confirm.View exposing (view)

import Html exposing (Html, button, div, input, label, table, tbody, td, text, tr)
import Html.Attributes exposing (disabled, type_)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Pages.Registration.Confirm.Page as Page
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = always True
        , initialization = Page.lenses.initialization.get
        , configuration = .configuration
        , currentPage = Nothing
        , showNavigation = False
        }
        model
    <|
        let
            isValid =
                model.password1 == model.password2

            enterAction =
                if isValid then
                    [ onEnter Page.Request ]

                else
                    []
        in
        div [ Style.classes.confirmation ]
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
                                    (Just >> Maybe.Extra.filter (String.isEmpty >> not) >> Page.SetDisplayName)
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
                                ([ onInput Page.SetPassword1
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
                                ([ onInput Page.SetPassword2
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
