module Pages.Confirmation.View exposing (view)

import Html exposing (Html, div, label, text)
import Pages.Confirmation.Page as Page
import Pages.Util.Links as Links
import Pages.Util.Style as Style


view : Page.Model -> Html Page.Msg
view model =
    div [ Style.classes.confirm ]
        [ div [ Style.classes.info ]
            [ label [] [ text "Please check your email. Follow the suggested instructions to continue." ]
            ]
        , div [ Style.classes.button.navigation ]
            [ Links.linkButton
                { url = Links.frontendPage model.configuration [ "login" ]
                , attributes = []
                , children = [ text "Main page" ]
                }
            ]
        ]
