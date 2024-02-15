package services.stats

import db._
import services.common.RequestInterval
import slick.dbio.DBIO

import scala.concurrent.{ ExecutionContext, Future }

trait StatsService {

  def nutrientsOverTime(userId: UserId, profileId: ProfileId, requestInterval: RequestInterval): Future[Stats]

  def nutrientsOfFood(foodId: FoodId): Future[Option[NutrientAmountMap]]
  def nutrientsOfComplexFood(userId: UserId, complexFoodId: ComplexFoodId): Future[Option[NutrientAmountMap]]
  def nutrientsOfRecipe(userId: UserId, recipeId: RecipeId): Future[Option[NutrientAmountMap]]

  def nutrientsOfMeal(userId: UserId, profileId: ProfileId, mealId: MealId): Future[NutrientAmountMap]

  def weightOfRecipe(userId: UserId, recipeId: RecipeId): Future[Option[BigDecimal]]
  def weightOfMeal(userId: UserId, profileId: ProfileId, mealId: MealId): Future[Option[BigDecimal]]

  def weightOfMeals(userId: UserId, profileId: ProfileId, mealIds: Seq[MealId]): Future[Option[BigDecimal]]

  def recipeOccurrences(userId: UserId, profileId: ProfileId): Future[Seq[RecipeOccurrence]]
}

object StatsService {

  trait Companion {

    def nutrientsOverTime(userId: UserId, profileId: ProfileId, requestInterval: RequestInterval)(implicit
        ec: ExecutionContext
    ): DBIO[Stats]

    def nutrientsOfFood(foodId: FoodId)(implicit ec: ExecutionContext): DBIO[Option[NutrientAmountMap]]

    def nutrientsOfComplexFood(userId: UserId, complexFoodId: ComplexFoodId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[NutrientAmountMap]]

    def nutrientsOfRecipe(userId: UserId, recipeId: RecipeId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[NutrientAmountMap]]

    def nutrientsOfMeal(userId: UserId, profileId: ProfileId, mealId: MealId)(implicit
        ec: ExecutionContext
    ): DBIO[NutrientAmountMap]

    def weightOfRecipe(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Option[BigDecimal]]

    def weightOfMeal(userId: UserId, profileId: ProfileId, mealId: MealId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[BigDecimal]]

    def weightOfMeals(userId: UserId, profileId: ProfileId, mealIds: Seq[MealId])(implicit
        ec: ExecutionContext
    ): DBIO[Option[BigDecimal]]

    def recipeOccurrences(userId: UserId, profileId: ProfileId)(implicit
        ec: ExecutionContext
    ): DBIO[Seq[RecipeOccurrence]]

  }

}
