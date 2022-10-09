module Pages.Login.View exposing (..)

import Addresses.Frontend
import Html exposing (Html, button, div, input, label, text)
import Html.Attributes exposing (autocomplete, type_)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Pages.Login.Page as Page
import Pages.Util.Links as Links
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = always True
        , initialization = .initialization
        , configuration = .configuration
        , jwt = always Nothing
        , currentPage = Just ViewUtil.Login
        , showNavigation = False
        }
        model
    <|
        div [ Style.classes.confirm ]
            [ div []
                [ label [] [ text "Nickname" ]
                , input
                    [ autocomplete True
                    , onInput Page.SetNickname
                    , onEnter Page.Login
                    , Style.classes.editable
                    ]
                    []
                ]
            , div []
                [ label [] [ text "Password" ]
                , input
                    [ type_ "password"
                    , autocomplete True
                    , onInput Page.SetPassword
                    , onEnter Page.Login
                    , Style.classes.editable
                    ]
                    []
                ]
            , div []
                [ button [ onClick Page.Login, Style.classes.button.confirm ] [ text "Log In" ] ]
            , div []
                [ Links.linkButton
                    { url = Links.frontendPage model.configuration <| Addresses.Frontend.requestRegistration.address ()
                    , attributes = [ Style.classes.button.navigation ]
                    , children = [ text "Create account" ]
                    }
                ]
            , div []
                [ Links.linkButton
                    { url = Links.frontendPage model.configuration <| Addresses.Frontend.requestRecovery.address ()
                    , attributes = [ Style.classes.button.navigation ]
                    , children = [ text "Recover account" ]
                    }
                ]
            ]
