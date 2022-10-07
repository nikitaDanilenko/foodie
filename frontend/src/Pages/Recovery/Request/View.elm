module Pages.Recovery.Request.View exposing (view)

import Html exposing (Html, button, div, input, label, table, tbody, td, text, tr)
import Html.Attributes exposing (disabled, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Pages.Recovery.Request.Page as Page
import Pages.Util.Links as Links
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = always True
        , initialization = Page.lenses.initialization.get
        , configuration = .configuration
        , jwt = always Nothing
        , currentPage = Nothing
        , showNavigation = False
        }
        model
    <|
        case model.mode of
            Page.Initial ->
                viewInitial model

            Page.Requesting ->
                viewRequesting model

            Page.Requested ->
                viewRequested model


viewInitial : Page.Model -> Html Page.Msg
viewInitial =
    div [ Style.classes.request ] << searchComponents


viewRequesting : Page.Model -> Html Page.Msg
viewRequesting model =
    let
        remainder =
            if List.isEmpty model.users then
                [ label [] [ text "No matching user found" ] ]

            else
                [ label [] [ text "Multiple users found. Please choose one." ]
                , div []
                    (List.map chooseUser model.users)
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
    div [ Style.classes.request ] (searchComponents model ++ remainder)


viewRequested : Page.Model -> Html Page.Msg
viewRequested model =
    div [ Style.classes.confirm ]
        [ div [] [ label [] [ text "Requested user recovery. Please check your email" ] ]
        , div []
            [ Links.toLoginButton
                { configuration = model.configuration
                , buttonText = "Main page"
                }
            ]
        ]


searchComponents model =
    let
        isValid =
            model.searchString |> String.isEmpty |> not

        enterAction =
            if isValid then
                [ onEnter Page.Find ]

            else
                []
    in
    [ div [] [ label [ Style.classes.info ] [ text "Recovery" ] ]
    , table []
        [ tbody []
            [ tr []
                [ td [] [ label [] [ text "Nickname or email" ] ]
                , td []
                    [ input
                        ([ onInput Page.SetSearchString
                         , Style.classes.editable
                         , value <| model.searchString
                         ]
                            ++ enterAction
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
