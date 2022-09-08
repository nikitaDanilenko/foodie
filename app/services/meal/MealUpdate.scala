package services.meal

import services.MealId
import utils.date.SimpleDate

case class MealUpdate(
    id: MealId,
    date: SimpleDate,
    name: Option[String]
)

object MealUpdate {

  def update(meal: Meal, mealUpdate: MealUpdate): Meal =
    meal.copy(
      date = mealUpdate.date,
      name = mealUpdate.name
    )

}
