package services.meal

import db.daos.meal.MealKey
import db.{ MealEntryId, MealId, ProfileId, UserId }
import errors.ServerError
import services.DBError
import services.common.RequestInterval
import slick.dbio.DBIO

import scala.concurrent.{ ExecutionContext, Future }

trait MealService {
  def allMeals(userId: UserId, profileId: ProfileId, interval: RequestInterval): Future[Seq[Meal]]
  def getMeal(userId: UserId, profileId: ProfileId, mealId: MealId): Future[Option[Meal]]

  def createMeal(userId: UserId, profileId: ProfileId, mealCreation: MealCreation): Future[ServerError.Or[Meal]]

  def updateMeal(
      userId: UserId,
      profileId: ProfileId,
      mealId: MealId,
      mealUpdate: MealUpdate
  ): Future[ServerError.Or[Meal]]

  def deleteMeal(userId: UserId, profileId: ProfileId, mealId: MealId): Future[Boolean]

  def getMealEntries(userId: UserId, profileId: ProfileId, mealIds: Seq[MealId]): Future[Map[MealKey, Seq[MealEntry]]]

  def addMealEntry(
      userId: UserId,
      profileId: ProfileId,
      mealId: MealId,
      mealEntryCreation: MealEntryCreation
  ): Future[ServerError.Or[MealEntry]]

  def updateMealEntry(
      userId: UserId,
      profileId: ProfileId,
      mealId: MealId,
      mealEntryId: MealEntryId,
      mealEntryUpdate: MealEntryUpdate
  ): Future[ServerError.Or[MealEntry]]

  def removeMealEntry(
      userId: UserId,
      profileId: ProfileId,
      mealId: MealId,
      mealEntryId: MealEntryId
  ): Future[Boolean]

}

object MealService {

  trait Companion {

    def allMeals(userId: UserId, profileId: ProfileId, interval: RequestInterval)(implicit
        ec: ExecutionContext
    ): DBIO[Seq[Meal]]

    def getMeal(userId: UserId, profileId: ProfileId, mealId: MealId)(implicit ec: ExecutionContext): DBIO[Option[Meal]]

    def getMeals(userId: UserId, profileId: ProfileId, mealIds: Seq[MealId])(implicit
        ec: ExecutionContext
    ): DBIO[Seq[Meal]]

    def createMeal(userId: UserId, profileId: ProfileId, mealId: MealId, mealCreation: MealCreation)(implicit
        ec: ExecutionContext
    ): DBIO[Meal]

    def updateMeal(userId: UserId, profileId: ProfileId, mealId: MealId, mealUpdate: MealUpdate)(implicit
        ec: ExecutionContext
    ): DBIO[Meal]

    def deleteMeal(userId: UserId, profileId: ProfileId, mealId: MealId)(implicit ec: ExecutionContext): DBIO[Boolean]

    def getMealEntries(userId: UserId, profileId: ProfileId, mealIds: Seq[MealId])(implicit
        ec: ExecutionContext
    ): DBIO[Map[MealKey, Seq[MealEntry]]]

    def addMealEntry(
        userId: UserId,
        profileId: ProfileId,
        mealId: MealId,
        mealEntryId: MealEntryId,
        mealEntryCreation: MealEntryCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[MealEntry]

    def updateMealEntry(
        userId: UserId,
        profileId: ProfileId,
        mealId: MealId,
        mealEntryId: MealEntryId,
        mealEntryUpdate: MealEntryUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[MealEntry]

    def removeMealEntry(
        userId: UserId,
        profileId: ProfileId,
        mealId: MealId,
        mealEntryId: MealEntryId
    )(implicit ec: ExecutionContext): DBIO[Boolean]

    final def notFound[A]: DBIO[A] = DBIO.failed(DBError.Meal.NotFound)
  }

}
