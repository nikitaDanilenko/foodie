package services.stats

import io.scalaland.chimney.dsl._
import services.meal.Meal
import services.nutrient.Nutrient

import java.time.LocalDate

case class Stats(
    meals: Seq[Meal],
    nutrientMap: Map[Nutrient, Amount]
)

object Stats {

  def dailyAverage(stats: Stats): Map[Nutrient, Option[BigDecimal]] = {
    val days = stats.meals
      .map(_.date.date)
      .distinct
      .map(_.transformInto[LocalDate])

    val modifier: BigDecimal => BigDecimal = if (days.nonEmpty) {
      val numberOfDays = 1 + days.max.toEpochDay - days.min.toEpochDay
      _ / numberOfDays
    } else _ => 0

    stats.nutrientMap.view
      .mapValues(a => a.value.map(modifier))
      .toMap
  }

}
