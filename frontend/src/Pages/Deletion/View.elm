module Pages.Deletion.View exposing (view)

import Html exposing (Html, button, div, label, table, tbody, td, text, tr)
import Html.Events exposing (onClick)
import Pages.Deletion.Page as Page
import Pages.Util.Links as Links
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
            Page.Checking ->
                viewChecking model

            Page.Confirmed ->
                viewConfirmed model


viewChecking : Page.Model -> Html Page.Msg
viewChecking model =
    div [ Style.classes.confirm ]
        [ label [ Style.classes.info ] [ text "Confirm deletion" ]
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
                ]
            ]
        , div []
            [ button
                [ onClick Page.Confirm
                , Style.classes.button.delete
                ]
                [ text "Delete" ]
            ]
        , div []
            [ Links.toLoginButton
                { configuration = model.configuration
                , buttonText = "Back to main"
                }
            ]
        ]


viewConfirmed : Page.Model -> Html Page.Msg
viewConfirmed model =
    div [ Style.classes.confirm ]
        [ div [] [ label [] [ text "User deletion successful." ] ]
        , div []
            [ Links.toLoginButton
                { configuration = model.configuration
                , buttonText = "Main page"
                }
            ]
        ]
