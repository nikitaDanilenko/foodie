package services.stats

import java.time.LocalDate

import io.scalaland.chimney.dsl._
import services.meal.Meal
import services.nutrient.NutrientMap

case class Stats(
    meals: Seq[Meal],
    nutrientMap: NutrientMap
)

object Stats {

  def dailyAverage(stats: Stats): NutrientMap = {
    val days = stats.meals
      .map(_.date.date)
      .distinct
      .map(_.transformInto[LocalDate])

    val modifier: BigDecimal => BigDecimal = if (days.nonEmpty) {
      val numberOfDays = 1 + days.max.toEpochDay - days.min.toEpochDay
      _ / numberOfDays
    } else _ => 0

    stats.nutrientMap.view
      .mapValues(modifier)
      .toMap
  }

}
