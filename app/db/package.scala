import utils.IdType

import java.util.UUID

package object db {

  object MealId extends IdType[UUID]
  type MealId = MealId.Type

  object MealEntryId extends IdType[UUID]
  type MealEntryId = MealEntryId.Type

  object NutrientId extends IdType[Int]
  type NutrientId = NutrientId.Type

  object NutrientCode extends IdType[Int]
  type NutrientCode = NutrientCode.Type

  object RecipeId extends IdType[UUID]
  type RecipeId = RecipeId.Type

  object IngredientId extends IdType[UUID]
  type IngredientId = IngredientId.Type

  object FoodId extends IdType[Int]
  type FoodId = FoodId.Type

  type ComplexFoodId = RecipeId

  object MeasureId extends IdType[Int]
  type MeasureId = MeasureId.Type

  object UserId extends IdType[UUID]
  type UserId = UserId.Type

  object ProfileId extends IdType[UUID]
  type ProfileId = ProfileId.Type

  object SessionId extends IdType[UUID]
  type SessionId = SessionId.Type

  object ReferenceMapId extends IdType[UUID]
  type ReferenceMapId = ReferenceMapId.Type

}
