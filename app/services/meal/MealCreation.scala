package services.meal

import services.MealId
import utils.date.SimpleDate

case class MealCreation(
    date: SimpleDate,
    name: Option[String]
)

object MealCreation {

  def create(id: MealId, mealCreation: MealCreation): Meal =
    Meal(
      id = id,
      date = mealCreation.date,
      name = mealCreation.name,
    )

}
