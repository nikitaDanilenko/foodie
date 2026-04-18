module Pages.Util.ProfileChoice.View exposing (viewWith)

import Api.Auxiliary exposing (ProfileId)
import Api.Types.Profile exposing (Profile)
import Html exposing (Html, li, menu, text)
import Pages.Util.Links as Links
import Pages.Util.ProfileChoice.Page as Page
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate


type alias Directions =
    { address : ProfileId -> List String
    , currentPage : ViewUtil.Page
    , modifier : Html Page.LogicMsg -> Html Page.LogicMsg
    }


viewWith : Directions -> Page.Model -> Html Page.Msg
viewWith ps =
    Tristate.view
        { viewMain = viewMainWith ps
        , showLoginRedirect = True
        }


viewMainWith : Directions -> Page.Main -> Html Page.LogicMsg
viewMainWith ps main =
    ViewUtil.viewMainWith
        { currentPage = Just ps.currentPage
        , showNavigation = True
        }
    <|
        ps.modifier <|
            menu []
                (List.map (viewProfileButtonWith ps) main.profiles)


viewProfileButtonWith : Directions -> Profile -> Html Page.LogicMsg
viewProfileButtonWith ps profile =
    li []
        [ Links.linkButton
            { url = Links.frontendPage <| ps.address <| .id <| profile
            , attributes = [ Style.classes.button.overview ]
            , children = [ text profile.name ]
            }
        ]
