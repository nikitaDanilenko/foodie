module Pages.Statistics.StatisticsView exposing (..)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Auxiliary exposing (NutrientCode, ProfileId, ReferenceMapId)
import Api.Types.NutrientInformationBase exposing (NutrientInformationBase)
import Api.Types.NutrientUnit as NutrientUnit
import Api.Types.Profile exposing (Profile)
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Basics.Extra exposing (flip)
import Dict exposing (Dict)
import Dropdown exposing (dropdown)
import FormatNumber
import FormatNumber.Locales
import Html exposing (Attribute, Html, div, label, table, tbody, td, text, th, thead, tr)
import List.Extra
import Maybe.Extra
import Pages.Statistics.StatisticsUtil exposing (ReferenceNutrientTree)
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Util.DictList as DictList exposing (DictList)
import Util.SearchUtil as SearchUtil
import Uuid


displayFloat : Float -> String
displayFloat =
    FormatNumber.format FormatNumber.Locales.frenchLocale
        >> String.replace "," "."


quotientInfo :
    { defined : Int
    , total : Int
    , value : Maybe a
    }
    -> String
quotientInfo ps =
    [ ps.defined, ps.total ]
        |> List.map String.fromInt
        |> String.join "/"
        |> Just
        |> Maybe.Extra.filter (\_ -> ps.value |> Maybe.Extra.isJust)
        |> Maybe.Extra.unwrap "" (\v -> [ " ", "(", v, ")" ] |> String.join "")


referenceFactor :
    { actualValue : Maybe Float
    , referenceValue : Maybe Float
    }
    -> Maybe Float
referenceFactor vs =
    vs.referenceValue
        |> Maybe.Extra.filter (\x -> x > 0)
        |> Maybe.andThen
            (\r ->
                vs.actualValue |> Maybe.map (\a -> 100 * (a / r))
            )


factorStyle : Maybe Float -> List (Attribute msg)
factorStyle factor =
    Maybe.Extra.unwrap []
        (\percent ->
            [ if percent > 100 then
                Style.classes.rating.high

              else if percent == 100 then
                Style.classes.rating.exact

              else
                Style.classes.rating.low
            ]
        )
        factor


navigationBar :
    { currentPage : Maybe StatisticsVariant.Page
    }
    -> Html msg
navigationBar ps =
    ViewUtil.navigationBarWith
        { navigationPages = navigationPages
        , pageToButton =
            \page ->
                ViewUtil.navigationToPageButtonWith
                    { page = page
                    , nameOf = StatisticsVariant.nameOfPage
                    , addressSuffix = StatisticsVariant.addressSuffix
                    , currentPage = ps.currentPage
                    }
        }


navigationPages : List StatisticsVariant.Page
navigationPages =
    [ StatisticsVariant.Food
    , StatisticsVariant.ComplexFood
    , StatisticsVariant.Recipe
    , StatisticsVariant.Meal
    , StatisticsVariant.Time
    , StatisticsVariant.RecipeOccurrences
    ]


withNavigationBar :
    { currentPage : Maybe StatisticsVariant.Page
    }
    -> Html msg
    -> Html msg
withNavigationBar ps html =
    div []
        [ navigationBar ps
        , html
        ]


type alias CompletenessFraction information =
    { definedValues : information -> Int
    , totalValues : information -> Int
    }


nutrientInformationLineWith :
    { amountOf : information -> Maybe Float
    , dailyAmountOf : information -> Maybe Float
    , showDailyAmount : Bool
    , completenessFraction : Maybe (CompletenessFraction information)
    , nutrientBase : information -> NutrientInformationBase
    }
    -> Dict NutrientCode Float
    -> information
    -> Html msg
nutrientInformationLineWith ps referenceValues information =
    let
        referenceValue =
            Dict.get (ps.nutrientBase information).nutrientCode referenceValues

        dailyValue =
            ps.dailyAmountOf information

        factor =
            referenceFactor
                { actualValue = dailyValue
                , referenceValue = referenceValue
                }

        amount =
            information |> ps.amountOf

        ( completenessInfo, completenessStyles ) =
            ps.completenessFraction
                |> Maybe.Extra.unwrap ( "", [] )
                    (\completenessFraction ->
                        let
                            defined =
                                information |> completenessFraction.definedValues

                            total =
                                information |> completenessFraction.totalValues
                        in
                        if defined == total then
                            ( "", [] )

                        else
                            ( quotientInfo
                                { defined = defined
                                , total = total
                                , value = amount
                                }
                            , [ Style.classes.incomplete ]
                            )
                    )

        displayValue =
            Maybe.Extra.unwrap "" displayFloat >> flip (++) completenessInfo

        dailyAverage =
            if ps.showDailyAmount then
                [ td [ Style.classes.numberCell ] [ label completenessStyles [ text <| Maybe.Extra.unwrap "" displayFloat <| dailyValue ] ] ]

            else
                []
    in
    tr [ Style.classes.editLine ]
        ([ td [ Style.classes.editable ] [ label [] [ text <| .name <| ps.nutrientBase <| information ] ]
         , td [ Style.classes.editable, Style.classes.numberCell ] [ label completenessStyles [ text <| displayValue <| ps.amountOf <| information ] ]
         ]
            ++ dailyAverage
            ++ [ td [ Style.classes.numberCell ] [ label [] [ text <| Maybe.Extra.unwrap "" displayFloat <| referenceValue ] ]
               , td [ Style.classes.numberCell ] [ label [] [ text <| NutrientUnit.toString <| .unit <| ps.nutrientBase <| information ] ]
               , td [ Style.classes.numberCell ]
                    [ label (factorStyle factor ++ completenessStyles)
                        [ text <|
                            Maybe.Extra.unwrap "" (displayFloat >> flip (++) "%") <|
                                factor
                        ]
                    ]
               ]
        )


nutrientTableHeader : { withDailyAverage : Bool } -> Html msg
nutrientTableHeader ps =
    let
        dailyAverageColumn =
            if ps.withDailyAverage then
                [ th [ Style.classes.numberLabel ] [ label [] [ text "Daily (avg.)" ] ] ]

            else
                []
    in
    thead []
        [ tr [ Style.classes.tableHeader ]
            ([ th [] [ label [] [ text "Name" ] ]
             , th [ Style.classes.numberLabel ] [ label [] [ text "Total" ] ]
             ]
                ++ dailyAverageColumn
                ++ [ th [ Style.classes.numberLabel ] [ label [] [ text "Reference daily" ] ]
                   , th [ Style.classes.numberLabel ] [ label [] [ text "Unit" ] ]
                   , th [ Style.classes.numberLabel ] [ label [] [ text "%" ] ]
                   ]
            )
        ]


referenceMapDropdownWith :
    { referenceTrees : model -> DictList ReferenceMapId ReferenceNutrientTree
    , referenceTree : model -> Maybe ReferenceNutrientTree

    -- todo: Technically, this should be Maybe ReferenceMapId.
    , onChange : Maybe String -> msg
    }
    -> model
    -> Html msg
referenceMapDropdownWith ps model =
    dropdown
        { items =
            model
                |> ps.referenceTrees
                |> DictList.values
                |> List.sortBy (.map >> .name)
                |> List.map
                    (\referenceTree ->
                        { value = referenceTree.map.id |> Uuid.toString
                        , text = referenceTree.map.name
                        , enabled = True
                        }
                    )
        , emptyItem =
            Just
                { value = ""
                , text = ""
                , enabled = True
                }
        , onChange = ps.onChange
        }
        []
        (model |> ps.referenceTree |> Maybe.map (.map >> .id >> Uuid.toString))


profileDropdownWith :
    { profiles : model -> DictList ProfileId Profile
    , profile : model -> Maybe Profile
    , onChange : Maybe ProfileId -> msg
    }
    -> model
    -> Html msg
profileDropdownWith ps model =
    dropdown
        { items =
            model
                |> ps.profiles
                |> DictList.values
                |> List.sortBy .name
                |> List.map
                    (\profile ->
                        { value = profile.id |> Uuid.toString
                        , text = profile.name
                        , enabled = True
                        }
                    )
        , emptyItem =
            Just
                { value = ""
                , text = ""
                , enabled = True
                }
        , onChange = Maybe.andThen Uuid.fromString >> ps.onChange
        }
        []
        (model |> ps.profile |> Maybe.map (.id >> Uuid.toString))


referenceMapSelection :
    { onReferenceMapSelection : Maybe String -> msg
    , referenceTrees : model -> DictList ReferenceMapId ReferenceNutrientTree
    , referenceTree : model -> Maybe ReferenceNutrientTree
    }
    -> model
    -> List (Html msg)
referenceMapSelection ps model =
    [ div [ Style.classes.elements ] [ text "Reference map" ]
    , div [ Style.classes.info ]
        [ referenceMapDropdownWith
            { referenceTrees = ps.referenceTrees
            , referenceTree = ps.referenceTree
            , onChange = ps.onReferenceMapSelection
            }
            model
        ]
    ]


profileSelection :
    { onProfileSelection : Maybe ProfileId -> msg
    , profiles : model -> DictList ProfileId Profile
    , profile : model -> Maybe Profile
    }
    -> model
    -> List (Html msg)
profileSelection ps model =
    [ profileDropdownWith
        { profiles = ps.profiles
        , profile = ps.profile
        , onChange = ps.onProfileSelection
        }
        model
    ]


statisticsTable :
    { onSearchStringChange : String -> msg
    , searchStringOf : model -> String
    , infoListOf : model -> List information
    , amountOf : information -> Maybe Float
    , dailyAmountOf : information -> Maybe Float
    , showDailyAmount : Bool
    , completenessFraction : Maybe (CompletenessFraction information)
    , nutrientBase : information -> NutrientInformationBase
    , referenceTree : model -> Maybe ReferenceNutrientTree
    , tableLabel : String
    }
    -> model
    -> List (Html msg)
statisticsTable ps model =
    [ div [ Style.classes.elements ] [ text <| ps.tableLabel ]
    , div [ Style.classes.info, Style.classes.nutrients ]
        [ HtmlUtil.searchAreaWith
            { msg = ps.onSearchStringChange
            , searchString = ps.searchStringOf model
            }
        , table [ Style.classes.elementsWithControlsTable ]
            [ nutrientTableHeader { withDailyAverage = ps.showDailyAmount }
            , tbody []
                (List.map
                    (model
                        |> ps.referenceTree
                        |> Maybe.Extra.unwrap Dict.empty .values
                        |> nutrientInformationLineWith
                            { amountOf = ps.amountOf
                            , dailyAmountOf = ps.dailyAmountOf
                            , showDailyAmount = ps.showDailyAmount
                            , completenessFraction = ps.completenessFraction
                            , nutrientBase = ps.nutrientBase
                            }
                    )
                    (model
                        |> ps.infoListOf
                        |> List.filter
                            (\information ->
                                [ information |> ps.nutrientBase |> .name, information |> ps.nutrientBase |> .symbol ]
                                    |> List.Extra.find (model |> ps.searchStringOf |> SearchUtil.search)
                                    |> Maybe.Extra.isJust
                            )
                    )
                )
            ]
        ]
    ]
