package services.meal

import services.{ MealEntryId, MealId, RecipeId }

case class MealEntryCreation(
    mealId: MealId,
    recipeId: RecipeId,
    numberOfServings: BigDecimal
)

object MealEntryCreation {

  def create(id: MealEntryId, mealEntryCreation: MealEntryCreation): MealEntry =
    MealEntry(
      id = id,
      recipeId = mealEntryCreation.recipeId,
      numberOfServings = mealEntryCreation.numberOfServings
    )

}
