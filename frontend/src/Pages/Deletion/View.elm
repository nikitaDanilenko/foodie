module Pages.Deletion.View exposing (view)

import Html exposing (Html, button, div, label, table, tbody, td, text, tr)
import Html.Events exposing (onClick)
import Pages.Deletion.Page as Page
import Pages.Util.Links as Links
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate


view : Page.Model -> Html Page.Msg
view =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }


viewMain : Page.Main -> Html Page.LogicMsg
viewMain main =
    ViewUtil.viewMainWith
        { currentPage = Nothing
        , showNavigation = False
        }
    <|
        case main.mode of
            Page.Checking ->
                viewChecking main

            Page.Confirmed ->
                viewConfirmed


viewChecking : Page.Main -> Html Page.LogicMsg
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
                { buttonText = "Back to main"
                }
            ]
        ]


viewConfirmed : Html Page.LogicMsg
viewConfirmed =
    div [ Style.classes.confirm ]
        [ div [] [ label [] [ text "User deletion successful." ] ]
        , div []
            [ Links.toLoginButton
                { buttonText = "Main page"
                }
            ]
        ]
