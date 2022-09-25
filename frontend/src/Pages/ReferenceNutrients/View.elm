module Pages.ReferenceNutrients.View exposing (view)

import Api.Types.Nutrient exposing (Nutrient)
import Api.Types.ReferenceNutrient exposing (ReferenceNutrient)
import Basics.Extra exposing (flip)
import Dict
import Either
import Html exposing (Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, colspan, disabled, id, scope, value)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Pages.ReferenceNutrients.Page as Page exposing (NutrientMap)
import Pages.ReferenceNutrients.ReferenceNutrientCreationClientInput as ReferenceNutrientCreationClientInput exposing (ReferenceNutrientCreationClientInput)
import Pages.ReferenceNutrients.ReferenceNutrientUpdateClientInput as ReferenceNutrientUpdateClientInput exposing (ReferenceNutrientUpdateClientInput)
import Pages.ReferenceNutrients.Status as Status
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.ValidatedInput as ValidatedInput
import Pages.Util.ViewUtil as ViewUtil
import Util.Editing as Editing
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = .initialization
        , flagsWithJWT = .flagsWithJWT
        }
        model
    <|
        let
            viewEditReferenceNutrients =
                List.map
                    (Either.unpack
                        (editOrDeleteReferenceNutrientLine model.nutrients)
                        (\e -> e.update |> editReferenceNutrientLine model.nutrients e.original)
                    )

            viewNutrients searchString =
                model.nutrients
                    |> Dict.filter (\_ v -> SearchUtil.search searchString v.name)
                    |> Dict.values
                    |> List.sortBy .name
                    |> List.map (viewNutrientLine model.nutrients model.referenceNutrients model.referenceNutrientsToAdd)

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
        div [ id "referenceNutrientEditor" ]
            [ div []
                [ table []
                    [ colgroup []
                        [ col [] []
                        , col [] []
                        , col [] []
                        , col [ stringProperty "span" "2" ] []
                        ]
                    , thead []
                        [ tr [ class "tableHeader" ]
                            [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                            , th [ scope "col", class "numberLabel" ] [ label [] [ text "Reference value" ] ]
                            , th [ scope "col", class "numberLabel" ] [ label [] [ text "Unit" ] ]
                            , th [ colspan 2, scope "colgroup", class "controlsGroup" ] []
                            ]
                        ]
                    , tbody []
                        (viewEditReferenceNutrients
                            (model.referenceNutrients
                                |> Dict.toList
                                |> List.sortBy (\( k, _ ) -> Page.nutrientNameOrEmpty model.nutrients k |> String.toLower)
                                |> List.map Tuple.second
                            )
                        )
                    ]
                ]
            , div [ class "addView" ]
                [ div [ class "addElement" ]
                    [ HtmlUtil.searchAreaWith
                        { msg = Page.SetNutrientsSearchString
                        , searchString = model.nutrientsSearchString
                        }
                    , table [ class "choiceTable" ]
                        [ colgroup []
                            [ col [] []
                            , col [] []
                            , col [] []
                            , col [ stringProperty "span" "2" ] []
                            ]
                        , thead []
                            [ tr [ class "tableHeader" ]
                                [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                                , th [ scope "col", class "numberLabel" ] [ label [] [ text referenceValue ] ]
                                , th [ scope "col", class "numberLabel" ] [ label [] [ text unit ] ]
                                , th [ colspan 2, scope "colgroup", class "controlsGroup" ] []
                                ]
                            ]
                        , tbody [] (viewNutrients model.nutrientsSearchString)
                        ]
                    ]
                ]
            ]


editOrDeleteReferenceNutrientLine : Page.NutrientMap -> ReferenceNutrient -> Html Page.Msg
editOrDeleteReferenceNutrientLine nutrientMap referenceNutrient =
    tr [ class "editing" ]
        [ td [ class "editable" ] [ label [] [ text <| Page.nutrientNameOrEmpty nutrientMap <| referenceNutrient.nutrientCode ] ]
        , td [ class "editable", class "numberLabel" ] [ label [] [ text <| String.fromFloat <| referenceNutrient.amount ] ]
        , td [ class "editable", class "numberLabel" ] [ label [] [ text <| Page.nutrientUnitOrEmpty nutrientMap <| referenceNutrient.nutrientCode ] ]
        , td [ class "controls" ] [ button [ class "editButton", onClick (Page.EnterEditReferenceNutrient referenceNutrient.nutrientCode) ] [ text "Edit" ] ]
        , td [ class "controls" ] [ button [ class "deleteButton", onClick (Page.DeleteReferenceNutrient referenceNutrient.nutrientCode) ] [ text "Delete" ] ]
        ]


editReferenceNutrientLine : Page.NutrientMap -> ReferenceNutrient -> ReferenceNutrientUpdateClientInput -> Html Page.Msg
editReferenceNutrientLine nutrientMap referenceNutrient referenceNutrientUpdateClientInput =
    let
        saveMsg =
            Page.SaveReferenceNutrientEdit referenceNutrientUpdateClientInput
    in
    tr [ id "editLine" ]
        [ td [] [ label [] [ text (referenceNutrient.nutrientCode |> Page.nutrientNameOrEmpty nutrientMap) ] ]
        , td [ class "numberCell" ]
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
                , class "numberLabel"
                ]
                []
            ]
        , td [ class "numberCell" ]
            [ label [ class "numberLabel" ]
                [ text <| Page.nutrientUnitOrEmpty nutrientMap <| referenceNutrient.nutrientCode
                ]
            ]
        , td []
            [ button [ class "confirmButton", onClick saveMsg ]
                [ text "Save" ]
            ]
        , td []
            [ button [ class "cancelButton", onClick (Page.ExitEditReferenceNutrientAt referenceNutrient.nutrientCode) ]
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
                    [ td [ class "editable", class "numberCell" ] []
                    , td [ class "editable", class "numberCell" ] []
                    , td [ class "controls" ] []
                    , td [] [ button [ class "selectButton", onClick (Page.SelectNutrient nutrient.code) ] [ text "Select" ] ]
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
                    [ td [ class "numberCell" ]
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
                            , class "numberLabel"
                            ]
                            []
                        ]
                    , td [ class "numberCell" ] [ label [] [ text (referenceNutrientToAdd.nutrientCode |> Page.nutrientUnitOrEmpty nutrientMap) ] ]
                    , td [ class "controls" ]
                        [ button
                            [ class "confirmButton"
                            , disabled (referenceNutrientToAdd.amount |> ValidatedInput.isValid |> not)
                            , onClick confirmMsg
                            ]
                            [ text <| confirmName ]
                        ]
                    , td [ class "controls" ] [ button [ class "cancelButton", onClick (Page.DeselectNutrient nutrient.code) ] [ text "Cancel" ] ]
                    ]
    in
    tr [ class "editing" ]
        (td [ class "editable" ] [ label [] [ text nutrient.name ] ]
            :: process
        )
