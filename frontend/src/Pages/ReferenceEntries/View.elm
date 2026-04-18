module Pages.ReferenceEntries.View exposing (view)

import Html exposing (Attribute, Html, div, label, text)
import Pages.ReferenceEntries.Entries.View
import Pages.ReferenceEntries.Map.View
import Pages.ReferenceEntries.Page as Page
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
        , showNavigation = True
        }
    <|
        div [ Style.ids.referenceEntryEditor ]
            [ div []
                [ Pages.ReferenceEntries.Map.View.viewMain main.map
                    |> Html.map Page.MapMsg
                ]
            , div [ Style.classes.elements ] [ label [] [ text "Reference values" ] ]
            , Pages.ReferenceEntries.Entries.View.viewReferenceEntries main.entries |> Html.map Page.EntriesMsg
            , div [ Style.classes.elements ] [ label [] [ text "Nutrients" ] ]
            , Pages.ReferenceEntries.Entries.View.viewNutrients main.entries |> Html.map Page.EntriesMsg
            ]
