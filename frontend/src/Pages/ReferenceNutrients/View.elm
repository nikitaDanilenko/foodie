module Pages.ReferenceNutrients.View exposing (view)

import Api.Types.Nutrient exposing (Nutrient)
import Api.Types.ReferenceNutrient exposing (ReferenceNutrient)
import Basics.Extra exposing (flip)
import Dict
import Either
import Html exposing (Html, button, div, input, label, td, text, thead, tr)
import Html.Attributes exposing (class, disabled, id, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Pages.ReferenceNutrients.Page as Page exposing (NutrientMap)
import Pages.ReferenceNutrients.ReferenceNutrientCreationClientInput as ReferenceNutrientCreationClientInput exposing (ReferenceNutrientCreationClientInput)
import Pages.ReferenceNutrients.ReferenceNutrientUpdateClientInput as ReferenceNutrientUpdateClientInput exposing (ReferenceNutrientUpdateClientInput)
import Pages.ReferenceNutrients.Status as Status
import Pages.Util.Links as Links
import Pages.Util.ValidatedInput as ValidatedInput
import Pages.Util.ViewUtil as ViewUtil
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
        in
        div [ id "referenceNutrient" ]
            [ div [ id "referenceNutrientView" ]
                (thead []
                    [ tr []
                        [ td [] [ label [] [ text "Name" ] ]
                        , td [] [ label [] [ text "Reference value" ] ]
                        , td [] [ label [] [ text "Unit" ] ]
                        ]
                    ]
                    :: viewEditReferenceNutrients
                        (model.referenceNutrients
                            |> Dict.toList
                            |> List.sortBy (\( k, _ ) -> Page.nutrientNameOrEmpty model.nutrients k |> String.toLower)
                            |> List.map Tuple.second
                        )
                )
            , div [ id "addReferenceNutrientView" ]
                (div [ id "addReferenceNutrient" ]
                    [ div [ id "searchField" ]
                        [ label [] [ text Links.lookingGlass ]
                        , input [ onInput Page.SetNutrientsSearchString ] []
                        ]
                    ]
                    :: thead []
                        [ tr []
                            [ td [] [ label [] [ text "Name" ] ]
                            ]
                        ]
                    :: viewNutrients model.nutrientsSearchString
                )
            ]


editOrDeleteReferenceNutrientLine : Page.NutrientMap -> ReferenceNutrient -> Html Page.Msg
editOrDeleteReferenceNutrientLine nutrientMap referenceNutrient =
    tr [ id "editingReferenceNutrient" ]
        [ td [] [ label [] [ text (referenceNutrient.nutrientCode |> Page.nutrientNameOrEmpty nutrientMap) ] ]
        , td [] [ label [] [ text (referenceNutrient.amount |> String.fromFloat) ] ]
        , td [] [ label [] [ text (referenceNutrient.nutrientCode |> Page.nutrientUnitOrEmpty nutrientMap) ] ]
        , td [] [ button [ class "button", onClick (Page.EnterEditReferenceNutrient referenceNutrient.nutrientCode) ] [ text "Edit" ] ]
        , td [] [ button [ class "button", onClick (Page.DeleteReferenceNutrient referenceNutrient.nutrientCode) ] [ text "Delete" ] ]
        ]


editReferenceNutrientLine : Page.NutrientMap -> ReferenceNutrient -> ReferenceNutrientUpdateClientInput -> Html Page.Msg
editReferenceNutrientLine nutrientMap referenceNutrient referenceNutrientUpdateClientInput =
    tr [ id "referenceNutrientLine" ]
        [ td [] [ label [] [ text (referenceNutrient.nutrientCode |> Page.nutrientNameOrEmpty nutrientMap) ] ]
        , td []
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
                , onEnter (Page.SaveReferenceNutrientEdit referenceNutrient.nutrientCode)
                ]
                []
            ]
        , td [] [ label [] [ text (referenceNutrient.nutrientCode |> Page.nutrientUnitOrEmpty nutrientMap) ] ]
        , td []
            [ button [ class "button", onClick (Page.SaveReferenceNutrientEdit referenceNutrient.nutrientCode) ]
                [ text "Save" ]
            ]
        , td []
            [ button [ class "button", onClick (Page.ExitEditReferenceNutrientAt referenceNutrient.nutrientCode) ]
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
                    [ td [] [ button [ class "button", onClick (Page.SelectNutrient nutrient.code) ] [ text "Select" ] ] ]

                Just referenceNutrientToAdd ->
                    [ td []
                        [ label [] [ text "Amount" ]
                        , input
                            [ value referenceNutrientToAdd.amount.text
                            , onInput
                                (flip
                                    (ValidatedInput.lift
                                        ReferenceNutrientCreationClientInput.lenses.amount
                                    ).set
                                    referenceNutrientToAdd
                                    >> Page.UpdateAddNutrient
                                )
                            , onEnter addMsg
                            ]
                            []
                        ]
                    , td [] [ label [] [ text (referenceNutrientToAdd.nutrientCode |> Page.nutrientUnitOrEmpty nutrientMap) ] ]
                    , td []
                        [ button
                            [ class "button"
                            , disabled (referenceNutrientToAdd.amount |> ValidatedInput.isValid |> not)
                            , onClick addMsg
                            ]
                            [ text
                                (if Dict.member referenceNutrientToAdd.nutrientCode referenceNutrients then
                                    "Update"

                                 else
                                    "Add"
                                )
                            ]
                        ]
                    , td [] [ button [ class "button", onClick (Page.DeselectNutrient nutrient.code) ] [ text "Cancel" ] ]
                    ]
    in
    tr [ id "addingNutrientLine" ]
        (td [] [ label [] [ text nutrient.name ] ]
            :: process
        )
