module Pages.Deletion.Confirmation.View exposing (view)

import Html exposing (Html, button, div, label, table, tbody, td, text, tr)
import Html.Events exposing (onClick)
import Pages.Deletion.Confirmation.Page as Page
import Pages.Util.Style as Style


view : Page.Model -> Html Page.Msg
view model =
    div [ Style.classes.confirm ]
        [ label [] [ text "Confirm deletion" ]
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
                    [ td []
                        [ button
                            [ onClick Page.Confirm
                            , Style.classes.button.delete
                            ]
                            [ text "Delete" ]
                        ]
                    , td []
                        [ button
                            [ onClick Page.NavigateToMain
                            , Style.classes.button.navigation
                            ]
                            [ text "Back to main" ]
                        ]
                    ]
                ]
            ]
        ]
