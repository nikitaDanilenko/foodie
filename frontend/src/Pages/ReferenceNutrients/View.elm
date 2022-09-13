module Pages.ReferenceNutrients.View exposing (view)

import Api.Types.ReferenceNutrient exposing (ReferenceNutrient)
import Api.Types.Nutrient exposing (Nutrient)
import Basics.Extra exposing (flip)
import Dict
import Either
import Html exposing (Html, button, div, input, label, td, text, thead, tr)
import Html.Attributes exposing (class, disabled, id, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import List.Extra
import Maybe.Extra
import Pages.ReferenceNutrients.ReferenceNutrientCreationClientInput as ReferenceNutrientCreationClientInput exposing (ReferenceNutrientCreationClientInput)
import Pages.ReferenceNutrients.ReferenceNutrientUpdateClientInput as ReferenceNutrientUpdateClientInput exposing (ReferenceNutrientUpdateClientInput)
import Pages.ReferenceNutrients.Page as Page exposing (NutrientMap)
import Pages.Util.Links as Links
import Pages.Util.ValidatedInput as ValidatedInput


view : Page.Model -> Html Page.Msg
view model =
    let
        viewEditReferenceNutrients =
            List.map
                (Either.unpack
                    (editOrDeleteReferenceNutrientLine model.nutrients)
                    (\e -> e.update |> editReferenceNutrientLine model.nutrients e.original)
                )

        viewNutrients searchString =
            model.nutrients
                |> Dict.filter (\_ v -> String.contains (String.toLower searchString) (String.toLower v.name))
                |> Dict.values
                |> List.sortBy .name
                |> List.map (viewNutrientLine model.referenceNutrientsToAdd)
    in
    div [ id "referenceNutrient" ]
        [  div [ id "referenceNutrientView" ]
            (thead []
                [ tr []
                    [ td [] [ label [] [ text "Name" ] ]
                    , td [] [ label [] [ text "Number of servings" ] ]
                    ]
                ]
                :: viewEditReferenceNutrients model.referenceNutrients
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
                        , td [] [ label [] [ text "Description" ] ]
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
        , td []
            [ button [ class "button", onClick (Page.SaveReferenceNutrientEdit referenceNutrient.nutrientCode) ]
                [ text "Save" ]
            ]
        , td []
            [ button [ class "button", onClick (Page.ExitEditReferenceNutrientAt referenceNutrient.nutrientCode) ]
                [ text "Cancel" ]
            ]
        ]


viewNutrientLine : List ReferenceNutrientCreationClientInput -> Nutrient -> Html Page.Msg
viewNutrientLine referenceNutrientsToAdd nutrient =
    let
        addMsg =
            Page.AddNutrient nutrient.code

        process =
            case List.Extra.find (\referenceNutrient -> referenceNutrient.nutrientCode == nutrient.code) referenceNutrientsToAdd of
                Nothing ->
                    [ td [] [ button [ class "button", onClick (Page.SelectNutrient nutrient.id) ] [ text "Select" ] ] ]

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
                    , td []
                        [ button
                            [ class "button"
                            , disabled
                                (List.Extra.find (\me -> me.nutrientCode == nutrient.id) referenceNutrientsToAdd
                                    |> Maybe.Extra.unwrap True (.amount >> ValidatedInput.isValid >> not)
                                )
                            , onClick addMsg
                            ]
                            [ text "Add" ]
                        ]
                    , td [] [ button [ class "button", onClick (Page.DeselectNutrient nutrient.id) ] [ text "Cancel" ] ]
                    ]
    in
    tr [ id "addingNutrientLine" ]
        (td [] [ label [] [ text nutrient.name ] ]
            :: process
        )
