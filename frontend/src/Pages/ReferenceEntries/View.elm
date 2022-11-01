module Pages.ReferenceEntries.View exposing (view)

import Api.Types.Nutrient exposing (Nutrient)
import Api.Types.ReferenceEntry exposing (ReferenceEntry)
import Basics.Extra exposing (flip)
import Dict
import Either
import Html exposing (Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, disabled, scope, value)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Pages.ReferenceEntries.Page as Page exposing (NutrientMap)
import Pages.ReferenceEntries.Pagination as Pagination
import Pages.ReferenceEntries.ReferenceEntryCreationClientInput as ReferenceEntryCreationClientInput exposing (ReferenceEntryCreationClientInput)
import Pages.ReferenceEntries.ReferenceEntryUpdateClientInput as ReferenceEntryUpdateClientInput exposing (ReferenceEntryUpdateClientInput)
import Pages.ReferenceEntries.Status as Status
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
        , configuration = .authorizedAccess >> .configuration
        , jwt = .authorizedAccess >> .jwt >> Just
        , currentPage = Nothing
        , showNavigation = True
        }
        model
    <|
        let
            viewEditReferenceEntry =
                Either.unpack
                    (editOrDeleteReferenceEntryLine model.nutrients)
                    (\e -> e.update |> editReferenceEntryLine model.nutrients e.original)

            viewEditReferenceEntries =
                model.referenceEntries
                    |> Dict.filter (\_ v -> SearchUtil.search model.referenceEntriesSearchString (Editing.field .nutrientCode v |> Page.nutrientNameOrEmpty model.nutrients))
                    |> Dict.toList
                    |> List.sortBy (\( k, _ ) -> Page.nutrientNameOrEmpty model.nutrients k |> String.toLower)
                    |> List.map Tuple.second
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.pagination |> Compose.lensWithLens Pagination.lenses.referenceEntries
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
                model.referenceEntriesToAdd
                    |> Dict.isEmpty
                    |> not

            ( referenceValue, unit ) =
                if anySelection then
                    ( "Reference value", "Unit" )

                else
                    ( "", "" )
        in
        div [ Style.ids.referenceEntryEditor ]
            [ div []
                [ HtmlUtil.searchAreaWith
                    { msg = Page.SetReferenceEntriesSearchString
                    , searchString = model.referenceEntriesSearchString
                    }
                , table []
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
                        (viewEditReferenceEntries
                            |> Paginate.page
                            |> List.map viewEditReferenceEntry
                        )
                    ]
                ]
            , div [ Style.classes.pagination ]
                [ ViewUtil.pagerButtons
                    { msg =
                        PaginationSettings.updateCurrentPage
                            { pagination = Page.lenses.pagination
                            , items = Pagination.lenses.referenceEntries
                            }
                            model
                            >> Page.SetPagination
                    , elements = viewEditReferenceEntries
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
                                |> List.map (viewNutrientLine model.nutrients model.referenceEntries model.referenceEntriesToAdd)
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


editOrDeleteReferenceEntryLine : Page.NutrientMap -> ReferenceEntry -> Html Page.Msg
editOrDeleteReferenceEntryLine nutrientMap referenceNutrient =
    let
        editMsg =
            Page.EnterEditReferenceEntry referenceNutrient.nutrientCode
    in
    tr [ Style.classes.editing ]
        [ td [ Style.classes.editable, onClick editMsg ] [ label [] [ text <| Page.nutrientNameOrEmpty nutrientMap <| referenceNutrient.nutrientCode ] ]
        , td [ Style.classes.editable, Style.classes.numberLabel, onClick editMsg ] [ label [] [ text <| String.fromFloat <| referenceNutrient.amount ] ]
        , td [ Style.classes.editable, Style.classes.numberLabel, onClick editMsg ] [ label [] [ text <| Page.nutrientUnitOrEmpty nutrientMap <| referenceNutrient.nutrientCode ] ]
        , td [ Style.classes.controls ] [ button [ Style.classes.button.edit, onClick editMsg ] [ text "Edit" ] ]
        , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.DeleteReferenceEntry referenceNutrient.nutrientCode) ] [ text "Delete" ] ]
        ]


editReferenceEntryLine : Page.NutrientMap -> ReferenceEntry -> ReferenceEntryUpdateClientInput -> Html Page.Msg
editReferenceEntryLine nutrientMap referenceNutrient referenceNutrientUpdateClientInput =
    let
        saveMsg =
            Page.SaveReferenceEntryEdit referenceNutrientUpdateClientInput

        cancelMsg =
            Page.ExitEditReferenceEntryAt referenceNutrient.nutrientCode
    in
    tr [ Style.classes.editLine ]
        [ td [] [ label [] [ text (referenceNutrient.nutrientCode |> Page.nutrientNameOrEmpty nutrientMap) ] ]
        , td [ Style.classes.numberCell ]
            [ input
                [ value
                    referenceNutrientUpdateClientInput.amount.text
                , onInput
                    (flip
                        (ValidatedInput.lift
                            ReferenceEntryUpdateClientInput.lenses.amount
                        ).set
                        referenceNutrientUpdateClientInput
                        >> Page.UpdateReferenceEntry
                    )
                , onEnter saveMsg
                , HtmlUtil.onEscape cancelMsg
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
            [ button [ Style.classes.button.cancel, onClick cancelMsg ]
                [ text "Cancel" ]
            ]
        ]


viewNutrientLine : Page.NutrientMap -> Page.ReferenceEntryOrUpdateMap -> Page.AddNutrientMap -> Nutrient -> Html Page.Msg
viewNutrientLine nutrientMap referenceEntries referenceEntriesToAdd nutrient =
    let
        addMsg =
            Page.AddNutrient nutrient.code

        selectMsg =
            Page.SelectNutrient nutrient.code

        cancelMsg =
            Page.DeselectNutrient nutrient.code

        maybeReferenceEntryToAdd =
            Dict.get nutrient.code referenceEntriesToAdd

        rowClickAction =
            if Maybe.Extra.isJust maybeReferenceEntryToAdd then
                []

            else
                [ onClick selectMsg ]

        process =
            case maybeReferenceEntryToAdd of
                Nothing ->
                    [ td [ Style.classes.editable, Style.classes.numberCell ] []
                    , td [ Style.classes.editable, Style.classes.numberCell ] []
                    , td [ Style.classes.controls ] []
                    , td [] [ button [ Style.classes.button.select, onClick selectMsg ] [ text "Select" ] ]
                    ]

                Just referenceNutrientToAdd ->
                    let
                        ( confirmName, confirmMsg, confirmStyle ) =
                            case Dict.get referenceNutrientToAdd.nutrientCode referenceEntries of
                                Nothing ->
                                    ( "Add", addMsg, Style.classes.button.confirm )

                                Just referenceNutrient ->
                                    ( "Update"
                                    , referenceNutrient
                                        |> Editing.field identity
                                        |> ReferenceEntryUpdateClientInput.from
                                        |> ReferenceEntryUpdateClientInput.lenses.amount.set referenceNutrientToAdd.amount
                                        |> Page.SaveReferenceEntryEdit
                                    , Style.classes.button.edit
                                    )
                    in
                    [ td [ Style.classes.numberCell ]
                        [ input
                            [ value referenceNutrientToAdd.amount.text
                            , onInput
                                (flip
                                    (ValidatedInput.lift
                                        ReferenceEntryCreationClientInput.lenses.amount
                                    ).set
                                    referenceNutrientToAdd
                                    >> Page.UpdateAddNutrient
                                )
                            , onEnter confirmMsg
                            , HtmlUtil.onEscape cancelMsg
                            , Style.classes.numberLabel
                            ]
                            []
                        ]
                    , td [ Style.classes.numberCell ] [ label [] [ text (referenceNutrientToAdd.nutrientCode |> Page.nutrientUnitOrEmpty nutrientMap) ] ]
                    , td [ Style.classes.controls ]
                        [ button
                            [ confirmStyle
                            , disabled (referenceNutrientToAdd.amount |> ValidatedInput.isValid |> not)
                            , onClick confirmMsg
                            ]
                            [ text <| confirmName ]
                        ]
                    , td [ Style.classes.controls ] [ button [ Style.classes.button.cancel, onClick cancelMsg ] [ text "Cancel" ] ]
                    ]
    in
    tr ([ Style.classes.editing ] ++ rowClickAction)
        (td [ Style.classes.editable ] [ label [] [ text nutrient.name ] ]
            :: process
        )
