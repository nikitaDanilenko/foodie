package services.meal

import services.{ MealId, RecipeId }
import utils.date.SimpleDate

case class MealUpdate(
    id: MealId,
    date: SimpleDate,
    name: Option[String],
    recipeId: RecipeId
)

object MealUpdate {

  def update(meal: Meal, mealUpdate: MealUpdate): Meal =
    meal.copy(
      date = mealUpdate.date,
      name = mealUpdate.name
    )

}
