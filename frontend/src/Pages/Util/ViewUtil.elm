module Pages.Util.ViewUtil exposing (..)

import Html exposing (Html, div, label, td, text, tr)
import Html.Attributes exposing (class)
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Pages.Util.Links as Links
import Url.Builder
import Util.Initialization exposing (Initialization(..))


viewWithErrorHandling :
    { isFinished : status -> Bool
    , initialization : model -> Initialization status
    , flagsWithJWT : model -> FlagsWithJWT
    }
    -> model
    -> Html msg
    -> Html msg
viewWithErrorHandling params model html =
    case params.initialization model of
        Failure explanation ->
            let
                solutionBlock =
                    if explanation.possibleSolution |> String.isEmpty then
                        []

                    else
                        [ td [] [ label [] [ text "Try the following:" ] ]
                        , td [] [ label [] [ text <| explanation.possibleSolution ] ]
                        ]

                redirectBlock =
                    if explanation.redirectToLogin then
                        [ td []
                            [ Links.linkButton
                                { url =
                                    Url.Builder.relative
                                        [ model |> params.flagsWithJWT |> .configuration |> .mainPageURL
                                        , "#"
                                        , "login"
                                        ]
                                        []
                                , attributes = [ class "button" ]
                                , children = [ text "Login" ]
                                , isDisabled = False
                                }
                            ]
                        ]

                    else
                        []
            in
            div []
                (tr []
                    [ td [] [ label [] [ text "An error occurred:" ] ]
                    , td [] [ label [] [ text <| explanation.cause ] ]
                    ]
                    :: [ tr [] solutionBlock, tr [] redirectBlock ]
                )

        Loading status ->
            if params.isFinished status then
                html

            else
                div [] [ Links.loadingSymbol ]
