package controllers.stats

import controllers.meal.Meal
import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps

@JsonCodec
case class Stats(
    meals: Seq[Meal],
    nutrients: Seq[NutrientInformation]
)

object Stats {

  implicit val fromDomain: Transformer[services.stats.Stats, Stats] = { stats =>
    val daily = services.stats.Stats.dailyAverage(stats)
    val nutrients = stats.nutrientMap.map {
      case (nutrient, amount) =>
        NutrientInformation(
          name = nutrient.name,
          unit = nutrient.unit.transformInto[NutrientUnit],
          amounts = Amounts(
            total = amount,
            dailyAverage = daily(nutrient)
          )
        )
    }.toSeq
    Stats(
      meals = stats.meals.map(_.transformInto[Meal]),
      nutrients = nutrients
    )
  }

}
