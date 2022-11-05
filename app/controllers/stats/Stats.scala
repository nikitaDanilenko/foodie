package controllers.stats

import controllers.meal.Meal
import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import cats.syntax.contravariantSemigroupal._

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
          nutrientCode = nutrient.code,
          name = nutrient.name,
          symbol = nutrient.symbol,
          unit = nutrient.unit.transformInto[NutrientUnit],
          amounts = Amounts(
            values = (amount.value, daily(nutrient)).mapN(Values.apply),
            numberOfIngredients = amount.numberOfIngredients.intValue,
            numberOfDefinedValues = amount.numberOfDefinedValues.intValue
          )
        )
    }.toSeq
    Stats(
      meals = stats.meals.map(_.transformInto[Meal]),
      nutrients = nutrients
    )
  }

}
