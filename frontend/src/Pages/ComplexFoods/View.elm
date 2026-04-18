module Pages.ComplexFoods.View exposing (..)

import Html exposing (Attribute, Html, div, label, text)
import Pages.ComplexFoods.Foods.View
import Pages.ComplexFoods.Page as Page
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate


view : Page.Model -> Html Page.Msg
view =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }


viewMain : Page.Main -> Html Page.LogicMsg
viewMain main =
    ViewUtil.viewMainWith
        { currentPage = Just ViewUtil.ComplexFoods
        , showNavigation = True
        }
    <|
        div [ Style.ids.complexFoodEditor ]
            [ div [ Style.classes.elements ] [ label [] [ text "Complex foods" ] ]
            , Pages.ComplexFoods.Foods.View.viewComplexFoods main.foods |> Html.map Page.FoodsMsg
            , div [ Style.classes.elements ] [ label [] [ text "Recipes" ] ]
            , Pages.ComplexFoods.Foods.View.viewRecipes main.foods |> Html.map Page.FoodsMsg
            ]
