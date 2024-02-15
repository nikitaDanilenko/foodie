import shapeless.tag.@@

import java.util.UUID

package object db {
  sealed trait MealTag

  type MealId = UUID @@ MealTag

  sealed trait MealEntryTag

  type MealEntryId = UUID @@ MealEntryTag

  sealed trait NutrientTag

  type NutrientId = Int @@ NutrientTag

  sealed trait NutrientCodeTag

  type NutrientCode = Int @@ NutrientCodeTag

  sealed trait RecipeTag

  type RecipeId = UUID @@ RecipeTag

  sealed trait IngredientTag

  type IngredientId = UUID @@ IngredientTag

  sealed trait FoodTag

  type FoodId = Int @@ FoodTag

  type ComplexFoodId = RecipeId

  sealed trait MeasureTag

  type MeasureId = Int @@ MeasureTag

  sealed trait UserTag

  type UserId = UUID @@ UserTag

  sealed trait ProfileTag

  type ProfileId = UUID @@ ProfileTag

  sealed trait SessionTag

  type SessionId = UUID @@ SessionTag

  sealed trait ReferenceMapTag

  type ReferenceMapId = UUID @@ ReferenceMapTag

}
