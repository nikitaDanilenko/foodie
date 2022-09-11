module Api.Lenses.StatsLens exposing (..)

import Api.Types.Meal exposing (Meal)
import Api.Types.NutrientInformation exposing (NutrientInformation)
import Api.Types.Stats exposing (Stats)
import Monocle.Lens exposing (Lens)


meals : Lens Stats (List Meal)
meals =
    Lens .meals (\b a -> { a | meals = b })


nutrients : Lens Stats (List NutrientInformation)
nutrients =
    Lens .nutrients (\b a -> { a | nutrients = b })
