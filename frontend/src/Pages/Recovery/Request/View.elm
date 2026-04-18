module Pages.Recovery.Request.View exposing (view)

import Html exposing (Html, button, div, input, label, table, tbody, td, text, tr)
import Html.Attributes exposing (disabled, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Pages.Recovery.Request.Page as Page
import Pages.Util.Links as Links
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate
import Util.MaybeUtil as MaybeUtil


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
            Page.Initial ->
                viewInitial main

            Page.Requesting ->
                viewRequesting main

            Page.Requested ->
                viewRequested


viewInitial : Page.Main -> Html Page.LogicMsg
viewInitial =
    div [ Style.classes.request ] << searchComponents


viewRequesting : Page.Main -> Html Page.LogicMsg
viewRequesting main =
    let
        remainder =
            if List.isEmpty main.users then
                [ label [] [ text "No matching user found" ] ]

            else
                [ label [] [ text "Multiple users found. Please choose one." ]
                , div []
                    (List.map chooseUser main.users)
                ]

        chooseUser user =
            div []
                [ button
                    [ onClick (Page.RequestRecovery user.id)
                    , Style.classes.button.navigation
                    ]
                    [ text user.nickname ]
                ]
    in
    div [ Style.classes.request ] (searchComponents main ++ remainder)


viewRequested : Html Page.LogicMsg
viewRequested =
    div [ Style.classes.confirm ]
        [ div [] [ label [] [ text "Requested user recovery. Please check your email" ] ]
        , div []
            [ Links.toLoginButton
                { buttonText = "Main page"
                }
            ]
        ]


searchComponents : Page.Main -> List (Html Page.LogicMsg)
searchComponents main =
    let
        isValid =
            main.searchString |> String.isEmpty |> not

        enterAction =
            MaybeUtil.optional isValid <| onEnter Page.Find
    in
    [ div [] [ label [ Style.classes.info ] [ text "Recovery" ] ]
    , table []
        [ tbody []
            [ tr []
                [ td [] [ label [] [ text "Nickname or email" ] ]
                , td []
                    [ input
                        ([ MaybeUtil.defined <| onInput Page.SetSearchString
                         , MaybeUtil.defined <| Style.classes.editable
                         , MaybeUtil.defined <| value <| main.searchString
                         , enterAction
                         ]
                            |> Maybe.Extra.values
                        )
                        []
                    ]
                ]
            ]
        ]
    , div []
        [ button
            [ onClick Page.Find
            , Style.classes.button.confirm
            , disabled <| not <| isValid
            ]
            [ text "Find" ]
        ]
    ]
