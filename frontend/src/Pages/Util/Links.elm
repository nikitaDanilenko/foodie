module Pages.Util.Links exposing (..)

import Basics.Extra exposing (flip)
import Bootstrap.Button
import Configuration exposing (Configuration)
import Html exposing (Attribute, Html)
import Html.Attributes exposing (href)
import Loading
import Url.Builder


linkButton :
    { url : String
    , attributes : List (Attribute msg)
    , children : List (Html msg)
    }
    -> Html msg
linkButton params =
    Bootstrap.Button.linkButton
        [ Bootstrap.Button.attrs (href params.url :: params.attributes)
        ]
        params.children


special : Int -> String
special =
    Char.fromCode >> String.fromChar


lookingGlass : String
lookingGlass =
    special 128269


loadingSymbol : Html msg
loadingSymbol =
    Loading.render Loading.Spinner Loading.defaultConfig Loading.On



-- todo: Switch parameter order


frontendPage : List String -> Configuration -> String
frontendPage pathSteps configuration =
    [ configuration.mainPageURL, "#" ]
        ++ pathSteps
        |> flip Url.Builder.relative []


backendPage : Configuration -> List String -> String
backendPage configuration pathSteps =
    (configuration.backendURL :: pathSteps) |> flip Url.Builder.relative []
