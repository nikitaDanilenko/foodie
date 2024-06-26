module Pages.Statistics.Meal.Select.Page exposing (..)

import Addresses.StatisticsVariant as StatisticsVariant exposing (Page)
import Api.Auxiliary exposing (JWT, MealId, ProfileId, ReferenceMapId)
import Api.Types.Meal exposing (Meal)
import Api.Types.Profile exposing (Profile)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Api.Types.TotalOnlyStats exposing (TotalOnlyStats)
import Monocle.Lens exposing (Lens)
import Pages.Statistics.StatisticsUtil as StatisticsUtil exposing (ReferenceNutrientTree, StatisticsEvaluation)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Util.DictList exposing (DictList)
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , meal : Meal
    , mealStats : TotalOnlyStats
    , profile : Profile
    , statisticsEvaluation : StatisticsEvaluation
    , variant : Page
    }


type alias Initial =
    { jwt : JWT
    , referenceTrees : Maybe (DictList ReferenceMapId ReferenceNutrientTree)
    , meal : Maybe Meal
    , mealStats : Maybe TotalOnlyStats
    , profile : Maybe Profile
    }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { jwt = authorizedAccess.jwt
    , referenceTrees = Nothing
    , meal = Nothing
    , mealStats = Nothing
    , profile = Nothing
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    Maybe.map4
        (\referenceTrees meal mealStats profile ->
            { jwt = i.jwt
            , meal = meal
            , mealStats = mealStats
            , profile = profile
            , statisticsEvaluation = StatisticsUtil.initialWith referenceTrees
            , variant = StatisticsVariant.Meal
            }
        )
        i.referenceTrees
        i.meal
        i.mealStats
        i.profile


lenses :
    { initial :
        { referenceTrees : Lens Initial (Maybe (DictList ReferenceMapId ReferenceNutrientTree))
        , meal : Lens Initial (Maybe Meal)
        , mealStats : Lens Initial (Maybe TotalOnlyStats)
        , profile : Lens Initial (Maybe Profile)
        }
    , main :
        { meal : Lens Main Meal
        , mealStats : Lens Main TotalOnlyStats
        , statisticsEvaluation : Lens Main StatisticsEvaluation
        }
    }
lenses =
    { initial =
        { referenceTrees = Lens .referenceTrees (\b a -> { a | referenceTrees = b })
        , meal = Lens .meal (\b a -> { a | meal = b })
        , mealStats = Lens .mealStats (\b a -> { a | mealStats = b })
        , profile = Lens .profile (\b a -> { a | profile = b })
        }
    , main =
        { meal = Lens .meal (\b a -> { a | meal = b })
        , mealStats = Lens .mealStats (\b a -> { a | mealStats = b })
        , statisticsEvaluation = Lens .statisticsEvaluation (\b a -> { a | statisticsEvaluation = b })
        }
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , profileId : ProfileId
    , mealId : MealId
    }


type alias Msg =
    Tristate.Msg LogicMsg


type LogicMsg
    = GotFetchStatsResponse (Result Error TotalOnlyStats)
    | GotFetchReferenceTreesResponse (Result Error (List ReferenceTree))
    | GotFetchMealResponse (Result Error Meal)
    | GotFetchProfileResponse (Result Error Profile)
    | SelectReferenceMap (Maybe ReferenceMapId)
    | SetNutrientsSearchString String
