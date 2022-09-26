module Pages.Util.ViewUtil exposing (Page(..), pagerButtons, paginate, viewWithErrorHandling)

import Html exposing (Html, button, div, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (disabled)
import Html.Events exposing (onClick)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings exposing (PaginationSettings)
import Pages.Util.Style as Style
import Paginate exposing (PaginatedList)
import Url.Builder
import Util.Initialization exposing (Initialization(..))


viewWithErrorHandling :
    { isFinished : status -> Bool
    , initialization : model -> Initialization status
    , flagsWithJWT : model -> FlagsWithJWT
    , currentPage : Maybe Page
    }
    -> model
    -> Html msg
    -> Html msg
viewWithErrorHandling params model html =
    let
        mainPageURL =
            model |> params.flagsWithJWT |> .configuration |> .mainPageURL
    in
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
                            [ navigationToPageButton
                                { page = Login
                                , mainPageURL = mainPageURL
                                , currentPage = Nothing
                                }
                            ]
                        ]

                    else
                        []
            in
            div [ Style.ids.error ]
                [ tr []
                    [ td [] [ label [] [ text "An error occurred:" ] ]
                    , td [] [ label [] [ text <| explanation.cause ] ]
                    ]
                , tr [] solutionBlock
                , tr [] redirectBlock
                ]

        Loading status ->
            if params.isFinished status then
                let
                    navigationLine =
                        case params.currentPage of
                            Just Overview ->
                                []

                            _ ->
                                [ navigationBar
                                    { mainPageURL = mainPageURL
                                    , currentPage = params.currentPage
                                    }
                                ]
                in
                div []
                    (navigationLine ++ [ html ])

            else
                div [] [ Links.loadingSymbol ]


type Page
    = Recipes
    | Meals
    | Statistics
    | ReferenceNutrients
    | Login
    | Overview


navigationPages : List Page
navigationPages =
    [ Recipes, Meals, Statistics, ReferenceNutrients ]


addressSuffix : Page -> String
addressSuffix page =
    case page of
        Recipes ->
            "recipes"

        Meals ->
            "meals"

        Statistics ->
            "statistics"

        ReferenceNutrients ->
            "reference-nutrients"

        Login ->
            "login"

        Overview ->
            "overview"


nameOf : Page -> String
nameOf page =
    case page of
        Recipes ->
            "Recipes"

        Meals ->
            "Meals"

        Statistics ->
            "Statistics"

        ReferenceNutrients ->
            "Reference nutrients"

        Login ->
            "Login"

        Overview ->
            "Overview"


navigationLink : { mainPageURL : String, page : String } -> String
navigationLink ps =
    Url.Builder.relative
        [ ps.mainPageURL
        , "#"
        , ps.page
        ]
        []


navigationToPageButton :
    { page : Page
    , mainPageURL : String
    , currentPage : Maybe Page
    }
    -> Html msg
navigationToPageButton ps =
    let
        isDisabled =
            Maybe.Extra.unwrap False (\current -> current == ps.page) ps.currentPage
    in
    if isDisabled then
        button
            [ Style.classes.button.navigation
            , Style.classes.disabled
            , disabled True
            ]
            [ text <| nameOf <| ps.page ]

    else
        Links.linkButton
            { url =
                navigationLink
                    { mainPageURL = ps.mainPageURL
                    , page = addressSuffix ps.page
                    }
            , attributes = [ Style.classes.button.navigation ]
            , children = [ text <| nameOf <| ps.page ]
            }


navigationBar :
    { mainPageURL : String
    , currentPage : Maybe Page
    }
    -> Html msg
navigationBar ps =
    div [ Style.ids.navigation ]
        [ table []
            [ thead []
                [ tr []
                    (navigationPages
                        |> List.map
                            (\page ->
                                th []
                                    [ navigationToPageButton
                                        { page = page
                                        , mainPageURL = ps.mainPageURL
                                        , currentPage = ps.currentPage
                                        }
                                    ]
                            )
                    )
                ]
            ]
        ]




pagerButtons :
    { msg : Int -> msg
    , elements : PaginatedList a
    }
    -> Html msg
pagerButtons ps =
    let
        pagerButton pageNum isCurrentPage =
            button
                ([ Style.classes.button.pager
                 , onClick (ps.msg pageNum)
                 ]
                    ++ (if isCurrentPage then
                            [ disabled True, Style.classes.disabled ]

                        else
                            []
                       )
                )
                [ text <| String.fromInt pageNum
                ]

        cells =
            if Paginate.totalPages ps.elements > 1 then
                Paginate.elidedPager
                    { innerWindow = 5
                    , outerWindow = 1
                    , pageNumberView = pagerButton
                    , gapView = button [ Style.classes.ellipsis ] [ text "..." ]
                    }
                    ps.elements
                    |> List.map (\elt -> td [] [ elt ])

            else
                []
    in
    table []
        [ tbody []
            [ tr []
                cells
            ]
        ]


paginate :
    { pagination : Lens model PaginationSettings
    }
    -> model
    -> List a
    -> PaginatedList a
paginate ps model =
    Paginate.fromList ((ps.pagination |> Compose.lensWithLens PaginationSettings.lenses.itemsPerPage).get model)
        >> Paginate.goTo (model |> (ps.pagination |> Compose.lensWithLens PaginationSettings.lenses.currentPage).get)
