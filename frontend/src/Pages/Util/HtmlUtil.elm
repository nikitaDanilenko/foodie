module Pages.Util.HtmlUtil exposing (onEscape, searchAreaWith)

import Html exposing (Attribute, Html, button, div, input, label, text)
import Html.Attributes exposing (disabled, value)
import Html.Events exposing (on, onClick, onInput)
import Keyboard.Event exposing (KeyboardEvent)
import Keyboard.Key as Key
import Maybe.Extra
import Pages.Util.Links as Links
import Pages.Util.Style as Style


searchAreaWith :
    { msg : String -> msg
    , searchString : String
    }
    -> Html msg
searchAreaWith ps =
    div [ Style.classes.search.area ]
        [ label [] [ text Links.lookingGlass ]
        , input
            [ onInput ps.msg
            , value <| ps.searchString
            , Style.classes.search.field
            ]
            []
        , button
            [ Style.classes.button.cancel
            , onClick (ps.msg "")
            , disabled <| String.isEmpty <| ps.searchString
            ]
            [ text "Clear" ]
        ]


onEscape : msg -> Attribute msg
onEscape =
    mkEscapeEventMsg
        >> Keyboard.Event.considerKeyboardEvent
        >> on "keydown"


mkEscapeEventMsg : msg -> KeyboardEvent -> Maybe msg
mkEscapeEventMsg msg keyboardEvent =
    Just msg |> Maybe.Extra.filter (always (keyboardEvent.keyCode == Key.Escape))
