module Pages.Registration.Request.View exposing (..)

import Basics.Extra exposing (flip)
import Html exposing (Html, button, div, input, label, table, tbody, td, text, tr)
import Html.Attributes exposing (disabled)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Monocle.Lens exposing (Lens)
import Pages.Registration.Request.Page as Page
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput
import Pages.Util.ViewUtil as ViewUtil
import Util.LensUtil as LensUtil


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
        div [ Style.classes.request ]
            [ div [] [ label [ Style.classes.info ] [ text "Registration" ] ]
            , table []
                [ tbody []
                    [ tr []
                        [ td [] [ label [] [ text "Nickname" ] ]
                        , td []
                            [ input
                                [ onInput
                                    (flip (ValidatedInput.lift LensUtil.identityLens).set model.nickname
                                        >> Page.SetNickname
                                    )
                                , onEnter Page.Request
                                , Style.classes.editable
                                ]
                                []
                            ]
                        ]
                    , tr []
                        [ td [] [ label [] [ text "Email" ] ]
                        , td []
                            [ input
                                [ onInput
                                    (flip (ValidatedInput.lift LensUtil.identityLens).set model.email
                                        >> Page.SetEmail
                                    )
                                , onEnter Page.Request
                                , Style.classes.editable
                                ]
                                []
                            ]
                        ]
                    ]
                ]
            , div []
                [ button
                    [ onClick Page.Request
                    , Style.classes.button.confirm
                    , disabled <| not <| ValidatedInput.isValid model.nickname && ValidatedInput.isValid model.email
                    ]
                    [ text "Register" ]
                ]
            ]
