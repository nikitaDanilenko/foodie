module Pages.Util.ViewUtil exposing (Page(..), navigationBarWith, navigationToPageButton, navigationToPageButtonWith, pagerButtons, paginate, viewMainWith)

import Addresses.Frontend
import Configuration exposing (Configuration)
import Html exposing (Html, button, div, main_, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (disabled)
import Html.Events exposing (onClick)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings exposing (PaginationSettings)
import Pages.Util.Style as Style
import Paginate exposing (PaginatedList)
import Url.Builder
import Util.MaybeUtil as MaybeUtil


viewMainWith :
    { configuration : Configuration
    , currentPage : Maybe Page
    , showNavigation : Bool
    }
    -> Html msg
    -> Html msg
viewMainWith params html =
    let
        navigation =
            [ navigationBar
                { mainPageURL = params.configuration |> .mainPageURL
                , currentPage = params.currentPage
                }
            ]
                |> List.filter (always params.showNavigation)
    in
    main_ []
        (navigation
            ++ [ html ]
        )


type Page
    = Recipes
    | MealsProfileChoice
    | Statistics
    | ReferenceMaps
    | UserSettings
    | Login
    | Overview
    | ComplexFoods
    | Profiles


navigationPages : List Page
navigationPages =
    [ Recipes, MealsProfileChoice, ComplexFoods, Statistics, ReferenceMaps, Profiles, UserSettings ]


addressSuffix : Page -> String
addressSuffix page =
    let
        parts =
            case page of
                Recipes ->
                    Addresses.Frontend.recipes.address ()

                MealsProfileChoice ->
                    Addresses.Frontend.mealBranch.address ()

                Statistics ->
                    Addresses.Frontend.statisticsTime.address ()

                ReferenceMaps ->
                    Addresses.Frontend.referenceMaps.address ()

                UserSettings ->
                    Addresses.Frontend.userSettings.address ()

                Login ->
                    Addresses.Frontend.login.address ()

                Overview ->
                    Addresses.Frontend.overview.address ()

                ComplexFoods ->
                    Addresses.Frontend.complexFoods.address ()

                Profiles ->
                    Addresses.Frontend.profiles.address ()
    in
    parts |> String.concat


nameOf : Page -> String
nameOf page =
    case page of
        Recipes ->
            "Recipes"

        MealsProfileChoice ->
            "Meals"

        Statistics ->
            "Statistics"

        ReferenceMaps ->
            "Reference maps"

        UserSettings ->
            "Settings"

        Login ->
            "Login"

        Overview ->
            "Overview"

        ComplexFoods ->
            "Complex foods"

        Profiles ->
            "Profiles"


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
    navigationToPageButtonWith
        { page = ps.page
        , nameOf = nameOf
        , addressSuffix = addressSuffix
        , mainPageURL = ps.mainPageURL
        , currentPage = ps.currentPage
        }


navigationToPageButtonWith :
    { page : page
    , nameOf : page -> String
    , addressSuffix : page -> String
    , mainPageURL : String
    , currentPage : Maybe page
    }
    -> Html msg
navigationToPageButtonWith ps =
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
            [ text <| ps.nameOf <| ps.page ]

    else
        Links.linkButton
            { url =
                navigationLink
                    { mainPageURL = ps.mainPageURL
                    , page = ps.addressSuffix ps.page
                    }
            , attributes = [ Style.classes.button.navigation ]
            , children = [ text <| ps.nameOf <| ps.page ]
            }


navigationBar :
    { mainPageURL : String
    , currentPage : Maybe Page
    }
    -> Html msg
navigationBar ps =
    navigationBarWith
        { navigationPages = navigationPages
        , pageToButton =
            \page ->
                navigationToPageButton
                    { page = page
                    , mainPageURL = ps.mainPageURL
                    , currentPage = ps.currentPage
                    }
        }


navigationBarWith :
    { navigationPages : List page
    , pageToButton : page -> Html msg
    }
    -> Html msg
navigationBarWith ps =
    div [ Style.ids.navigation ]
        [ table []
            [ thead []
                [ tr []
                    (ps.navigationPages
                        |> List.map
                            (\page ->
                                th []
                                    [ ps.pageToButton page
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
                ([ MaybeUtil.defined <| Style.classes.button.pager
                 , MaybeUtil.defined <| onClick <| ps.msg <| pageNum
                 , MaybeUtil.optional isCurrentPage <| disabled <| True
                 , MaybeUtil.optional isCurrentPage <| Style.classes.disabled
                 ]
                    |> Maybe.Extra.values
                )
                [ text <| String.fromInt pageNum
                ]

        cells =
            Paginate.elidedPager
                { innerWindow = 5
                , outerWindow = 1
                , pageNumberView = pagerButton
                , gapView = button [ Style.classes.ellipsis ] [ text "..." ]
                }
                ps.elements
                |> List.map (\elt -> td [] [ elt ])
                |> List.filter (Paginate.totalPages ps.elements > 1 |> always)
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
