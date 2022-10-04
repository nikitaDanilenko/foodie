module Pages.Deletion.Completion.View exposing (view)

import Html exposing (Html, div, label, text)
import Pages.Deletion.Completion.Page as Page
import Pages.Util.Links as Links
import Pages.Util.Style as Style


view : Page.Model -> Html Page.Msg
view model =
    div [ Style.classes.info ]
        [ label [] [ text "Account has been deleted." ]
        , Links.linkButton
            { url = Links.frontendPage [ "login" ] model.configuration
            , attributes = [ Style.classes.button.navigation ]
            , children = [ text "Main page" ]
            }
        ]
