module Pages.ReferenceNutrients.View exposing (view)

import Api.Types.Nutrient exposing (Nutrient)
import Api.Types.ReferenceNutrient exposing (ReferenceNutrient)
import Basics.Extra exposing (flip)
import Dict
import Either
import Html exposing (Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, disabled, scope, value)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Monocle.Compose as Compose
import Pages.ReferenceNutrients.Page as Page exposing (NutrientMap)
import Pages.ReferenceNutrients.Pagination as Pagination
import Pages.ReferenceNutrients.ReferenceNutrientCreationClientInput as ReferenceNutrientCreationClientInput exposing (ReferenceNutrientCreationClientInput)
import Pages.ReferenceNutrients.ReferenceNutrientUpdateClientInput as ReferenceNutrientUpdateClientInput exposing (ReferenceNutrientUpdateClientInput)
import Pages.ReferenceNutrients.Status as Status
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput
import Pages.Util.ViewUtil as ViewUtil
import Paginate
import Util.Editing as Editing
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = .initialization
        , flagsWithJWT = .flagsWithJWT
        , currentPage = Just ViewUtil.ReferenceNutrients
        }
        model
    <|
        let
            viewEditReferenceNutrient =
                Either.unpack
                    (editOrDeleteReferenceNutrientLine model.nutrients)
                    (\e -> e.update |> editReferenceNutrientLine model.nutrients e.original)

            viewEditReferenceNutrients =
                model.referenceNutrients
                    |> Dict.toList
                    |> List.sortBy (\( k, _ ) -> Page.nutrientNameOrEmpty model.nutrients k |> String.toLower)
                    |> List.map Tuple.second
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.pagination |> Compose.lensWithLens Pagination.lenses.referenceNutrients
                        }
                        model

            viewNutrients =
                model.nutrients
                    |> Dict.filter (\_ v -> SearchUtil.search model.nutrientsSearchString v.name)
                    |> Dict.values
                    |> List.sortBy .name
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.pagination |> Compose.lensWithLens Pagination.lenses.nutrients
                        }
                        model

            anySelection =
                model.referenceNutrientsToAdd
                    |> Dict.isEmpty
                    |> not

            ( referenceValue, unit ) =
                if anySelection then
                    ( "Reference value", "Unit" )

                else
                    ( "", "" )
        in
        div [ Style.ids.referenceNutrientEditor ]
            [ div []
                [ table []
                    [ colgroup []
                        [ col [] []
                        , col [] []
                        , col [] []
                        , col [ stringProperty "span" "2" ] []
                        ]
                    , thead []
                        [ tr [ Style.classes.tableHeader ]
                            [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                            , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text "Reference value" ] ]
                            , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text "Unit" ] ]
                            , th [ colspan 2, scope "colgroup", Style.classes.controlsGroup ] []
                            ]
                        ]
                    , tbody []
                        (viewEditReferenceNutrients
                            |> Paginate.page
                            |> List.map viewEditReferenceNutrient
                        )
                    ]
                ]
            , div [ Style.classes.pagination ]
                [ ViewUtil.pagerButtons
                    { msg =
                        PaginationSettings.updateCurrentPage
                            { pagination = Page.lenses.pagination
                            , items = Pagination.lenses.referenceNutrients
                            }
                            model
                            >> Page.SetPagination
                    , elements = viewEditReferenceNutrients
                    }
                ]
            , div [ Style.classes.addView ]
                [ div [ Style.classes.addElement ]
                    [ HtmlUtil.searchAreaWith
                        { msg = Page.SetNutrientsSearchString
                        , searchString = model.nutrientsSearchString
                        }
                    , table [ Style.classes.choiceTable ]
                        [ colgroup []
                            [ col [] []
                            , col [] []
                            , col [] []
                            , col [ stringProperty "span" "2" ] []
                            ]
                        , thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                                , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text referenceValue ] ]
                                , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text unit ] ]
                                , th [ colspan 2, scope "colgroup", Style.classes.controlsGroup ] []
                                ]
                            ]
                        , tbody []
                            (viewNutrients
                                |> Paginate.page
                                |> List.map (viewNutrientLine model.nutrients model.referenceNutrients model.referenceNutrientsToAdd)
                            )
                        ]
                    , div [ Style.classes.pagination ]
                        [ ViewUtil.pagerButtons
                            { msg =
                                PaginationSettings.updateCurrentPage
                                    { pagination = Page.lenses.pagination
                                    , items = Pagination.lenses.nutrients
                                    }
                                    model
                                    >> Page.SetPagination
                            , elements = viewNutrients
                            }
                        ]
                    ]
                ]
            ]


editOrDeleteReferenceNutrientLine : Page.NutrientMap -> ReferenceNutrient -> Html Page.Msg
editOrDeleteReferenceNutrientLine nutrientMap referenceNutrient =
    tr [ Style.classes.editing ]
        [ td [ Style.classes.editable ] [ label [] [ text <| Page.nutrientNameOrEmpty nutrientMap <| referenceNutrient.nutrientCode ] ]
        , td [ Style.classes.editable, Style.classes.numberLabel ] [ label [] [ text <| String.fromFloat <| referenceNutrient.amount ] ]
        , td [ Style.classes.editable, Style.classes.numberLabel ] [ label [] [ text <| Page.nutrientUnitOrEmpty nutrientMap <| referenceNutrient.nutrientCode ] ]
        , td [ Style.classes.controls ] [ button [ Style.classes.button.edit, onClick (Page.EnterEditReferenceNutrient referenceNutrient.nutrientCode) ] [ text "Edit" ] ]
        , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.DeleteReferenceNutrient referenceNutrient.nutrientCode) ] [ text "Delete" ] ]
        ]


editReferenceNutrientLine : Page.NutrientMap -> ReferenceNutrient -> ReferenceNutrientUpdateClientInput -> Html Page.Msg
editReferenceNutrientLine nutrientMap referenceNutrient referenceNutrientUpdateClientInput =
    let
        saveMsg =
            Page.SaveReferenceNutrientEdit referenceNutrientUpdateClientInput
    in
    tr [ Style.classes.editLine ]
        [ td [] [ label [] [ text (referenceNutrient.nutrientCode |> Page.nutrientNameOrEmpty nutrientMap) ] ]
        , td [ Style.classes.numberCell ]
            [ input
                [ value
                    (referenceNutrientUpdateClientInput.amount.value
                        |> String.fromFloat
                    )
                , onInput
                    (flip
                        (ValidatedInput.lift
                            ReferenceNutrientUpdateClientInput.lenses.amount
                        ).set
                        referenceNutrientUpdateClientInput
                        >> Page.UpdateReferenceNutrient
                    )
                , onEnter saveMsg
                , Style.classes.numberLabel
                ]
                []
            ]
        , td [ Style.classes.numberCell ]
            [ label [ Style.classes.numberLabel ]
                [ text <| Page.nutrientUnitOrEmpty nutrientMap <| referenceNutrient.nutrientCode
                ]
            ]
        , td []
            [ button [ Style.classes.button.confirm, onClick saveMsg ]
                [ text "Save" ]
            ]
        , td []
            [ button [ Style.classes.button.cancel, onClick (Page.ExitEditReferenceNutrientAt referenceNutrient.nutrientCode) ]
                [ text "Cancel" ]
            ]
        ]


viewNutrientLine : Page.NutrientMap -> Page.ReferenceNutrientOrUpdateMap -> Page.AddNutrientMap -> Nutrient -> Html Page.Msg
viewNutrientLine nutrientMap referenceNutrients referenceNutrientsToAdd nutrient =
    let
        addMsg =
            Page.AddNutrient nutrient.code

        process =
            case Dict.get nutrient.code referenceNutrientsToAdd of
                Nothing ->
                    [ td [ Style.classes.editable, Style.classes.numberCell ] []
                    , td [ Style.classes.editable, Style.classes.numberCell ] []
                    , td [ Style.classes.controls ] []
                    , td [] [ button [ Style.classes.button.select, onClick (Page.SelectNutrient nutrient.code) ] [ text "Select" ] ]
                    ]

                Just referenceNutrientToAdd ->
                    let
                        ( confirmName, confirmMsg ) =
                            case Dict.get referenceNutrientToAdd.nutrientCode referenceNutrients of
                                Nothing ->
                                    ( "Add", addMsg )

                                Just referenceNutrient ->
                                    ( "Update"
                                    , referenceNutrient
                                        |> Editing.field identity
                                        |> ReferenceNutrientUpdateClientInput.from
                                        |> ReferenceNutrientUpdateClientInput.lenses.amount.set referenceNutrientToAdd.amount
                                        |> Page.SaveReferenceNutrientEdit
                                    )
                    in
                    [ td [ Style.classes.numberCell ]
                        [ input
                            [ value referenceNutrientToAdd.amount.text
                            , onInput
                                (flip
                                    (ValidatedInput.lift
                                        ReferenceNutrientCreationClientInput.lenses.amount
                                    ).set
                                    referenceNutrientToAdd
                                    >> Page.UpdateAddNutrient
                                )
                            , onEnter confirmMsg
                            , Style.classes.numberLabel
                            ]
                            []
                        ]
                    , td [ Style.classes.numberCell ] [ label [] [ text (referenceNutrientToAdd.nutrientCode |> Page.nutrientUnitOrEmpty nutrientMap) ] ]
                    , td [ Style.classes.controls ]
                        [ button
                            [ Style.classes.button.confirm
                            , disabled (referenceNutrientToAdd.amount |> ValidatedInput.isValid |> not)
                            , onClick confirmMsg
                            ]
                            [ text <| confirmName ]
                        ]
                    , td [ Style.classes.controls ] [ button [ Style.classes.button.cancel, onClick (Page.DeselectNutrient nutrient.code) ] [ text "Cancel" ] ]
                    ]
    in
    tr [ Style.classes.editing ]
        (td [ Style.classes.editable ] [ label [] [ text nutrient.name ] ]
            :: process
        )
