package services.meal

import services.{ MealEntryId, RecipeId }

case class MealEntryUpdate(
    id: MealEntryId,
    recipeId: RecipeId,
    numberOfServings: BigDecimal
)

object MealEntryUpdate {

  def update(mealEntry: MealEntry, mealEntryUpdate: MealEntryUpdate): MealEntry =
    mealEntry.copy(
      numberOfServings = mealEntryUpdate.numberOfServings
    )

}
