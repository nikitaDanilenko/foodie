module Pages.Util.HtmlUtil exposing (..)

import Html exposing (Html, button, div, input, label, text)
import Html.Attributes exposing (class, disabled, value)
import Html.Events exposing (onClick, onInput)
import Pages.Util.Links as Links
import Pages.Util.Style as Style


searchAreaWith :
    { msg : String -> msg
    , searchString : String
    }
    -> Html msg
searchAreaWith ps =
    div [ class "searchArea" ]
        [ label [] [ text Links.lookingGlass ]
        , input
            [ onInput ps.msg
            , value <| ps.searchString
            , class "searchField"
            ]
            []
        , button
            [ Style.classes.button.cancel
            , onClick (ps.msg "")
            , disabled <| String.isEmpty <| ps.searchString
            ]
            [ text "Clear" ]
        ]