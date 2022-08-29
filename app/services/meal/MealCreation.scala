package services.meal

import services.{ MealId, RecipeId }
import utils.date.SimpleDate

case class MealCreation(
    date: SimpleDate,
    name: Option[String],
    recipeId: RecipeId,
    amount: BigDecimal
)

object MealCreation {

  def create(id: MealId, mealCreation: MealCreation): Meal =
    Meal(
      id = id,
      date = mealCreation.date,
      name = mealCreation.name,
      entries = Seq.empty
    )

}
