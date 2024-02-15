package services.meal

import cats.data.OptionT
import db.daos.meal.MealKey
import db.daos.mealEntry.MealEntryKey
import db.generated.Tables
import db.{ MealEntryId, MealId, ProfileId, UserId }
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.syntax._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.DBError
import services.common.RequestInterval
import services.common.Transactionally.syntax._
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

class Live @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider,
    companion: MealService.Companion
)(implicit
    executionContext: ExecutionContext
) extends MealService
    with HasDatabaseConfigProvider[PostgresProfile] {

  override def allMeals(userId: UserId, profileId: ProfileId, interval: RequestInterval): Future[Seq[Meal]] =
    db.runTransactionally(companion.allMeals(userId, profileId, interval))

  override def getMeal(userId: UserId, profileId: ProfileId, mealId: MealId): Future[Option[Meal]] =
    db.runTransactionally(companion.getMeal(userId, profileId, mealId))

  override def createMeal(
      userId: UserId,
      profileId: ProfileId,
      mealCreation: MealCreation
  ): Future[ServerError.Or[Meal]] =
    db.runTransactionally(
      companion.createMeal(userId, profileId, UUID.randomUUID().transformInto[MealId], mealCreation)
    ).map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Meal.Creation(error.getMessage).asServerError)
      }

  override def updateMeal(
      userId: UserId,
      profileId: ProfileId,
      mealId: MealId,
      mealUpdate: MealUpdate
  ): Future[ServerError.Or[Meal]] =
    db.runTransactionally(companion.updateMeal(userId, profileId, mealId, mealUpdate))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Meal.Update(error.getMessage).asServerError)
      }

  override def deleteMeal(userId: UserId, profileId: ProfileId, mealId: MealId): Future[Boolean] =
    db.runTransactionally(companion.deleteMeal(userId, profileId, mealId))

  override def getMealEntries(
      userId: UserId,
      profileId: ProfileId,
      mealIds: Seq[MealId]
  ): Future[Map[MealKey, Seq[MealEntry]]] =
    db.runTransactionally(companion.getMealEntries(userId, profileId, mealIds))

  override def addMealEntry(
      userId: UserId,
      profileId: ProfileId,
      mealId: MealId,
      mealEntryCreation: MealEntryCreation
  ): Future[ServerError.Or[MealEntry]] =
    db.runTransactionally(
      companion.addMealEntry(
        userId,
        profileId,
        mealId,
        UUID.randomUUID().transformInto[MealEntryId],
        mealEntryCreation
      )
    ).map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Meal.Entry.Creation(error.getMessage).asServerError)
      }

  override def updateMealEntry(
      userId: UserId,
      profileId: ProfileId,
      mealId: MealId,
      mealEntryId: MealEntryId,
      mealEntryUpdate: MealEntryUpdate
  ): Future[ServerError.Or[MealEntry]] =
    db.runTransactionally(companion.updateMealEntry(userId, profileId, mealId, mealEntryId, mealEntryUpdate))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Meal.Entry.Update(error.getMessage).asServerError)
      }

  override def removeMealEntry(
      userId: UserId,
      profileId: ProfileId,
      mealId: MealId,
      mealEntryId: MealEntryId
  ): Future[Boolean] =
    db.runTransactionally(companion.removeMealEntry(userId, profileId, mealId, mealEntryId))
      .recover { _ => false }

}

object Live {

  class Companion @Inject() (
      mealDao: db.daos.meal.DAO,
      mealEntryDao: db.daos.mealEntry.DAO
  ) extends MealService.Companion {

    override def allMeals(
        userId: UserId,
        profileId: ProfileId,
        interval: RequestInterval
    )(implicit
        ec: ExecutionContext
    ): DBIO[Seq[Meal]] =
      mealDao
        .allInInterval(userId, interval)
        .map(
          _.map(_.transformInto[Meal])
        )

    override def getMeal(
        userId: UserId,
        profileId: ProfileId,
        mealId: MealId
    )(implicit ec: ExecutionContext): DBIO[Option[Meal]] =
      OptionT(
        mealDao.find(MealKey(userId, profileId, mealId))
      ).map(_.transformInto[Meal]).value

    override def getMeals(
        userId: UserId,
        profileId: ProfileId,
        mealIds: Seq[MealId]
    )(implicit ec: ExecutionContext): DBIO[Seq[Meal]] =
      mealDao
        .allOf(userId, mealIds)
        .map(_.map(_.transformInto[Meal]))

    override def createMeal(
        userId: UserId,
        profileId: ProfileId,
        mealId: MealId,
        mealCreation: MealCreation
    )(implicit ec: ExecutionContext): DBIO[Meal] = {
      val meal    = MealCreation.create(mealId, mealCreation)
      val mealRow = Meal.TransformableToDB(userId, profileId, meal).transformInto[Tables.MealRow]
      mealDao
        .insert(mealRow)
        .map(_.transformInto[Meal])
    }

    override def updateMeal(
        userId: UserId,
        profileId: ProfileId,
        mealId: MealId,
        mealUpdate: MealUpdate
    )(implicit ec: ExecutionContext): DBIO[Meal] = {
      val findAction = OptionT(getMeal(userId, profileId, mealId))
        .getOrElseF(notFound)

      for {
        meal <- findAction
        _ <- mealDao.update(
          Meal
            .TransformableToDB(
              userId,
              profileId,
              MealUpdate.update(meal, mealUpdate)
            )
            .transformInto[Tables.MealRow]
        )
        updatedMeal <- findAction
      } yield updatedMeal
    }

    override def deleteMeal(
        userId: UserId,
        profileId: ProfileId,
        mealId: MealId
    )(implicit ec: ExecutionContext): DBIO[Boolean] =
      mealDao
        .delete(MealKey(userId, profileId, mealId))
        .map(_ > 0)

    override def getMealEntries(userId: UserId, profileId: ProfileId, mealIds: Seq[MealId])(implicit
        ec: ExecutionContext
    ): DBIO[Map[MealKey, Seq[MealEntry]]] =
      for {
        matchingMeals <- mealDao.allOf(userId, mealIds)
        mealEntries <-
          mealEntryDao
            .findAllFor(userId, profileId, matchingMeals.map(_.id.transformInto[MealId]))
            .map {
              _.view.mapValues(_.map(_.transformInto[MealEntry])).toMap
            }
      } yield mealEntries

    override def addMealEntry(
        userId: UserId,
        profileId: ProfileId,
        mealId: MealId,
        mealEntryId: MealEntryId,
        mealEntryCreation: MealEntryCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[MealEntry] = {
      val mealEntry = MealEntryCreation.create(mealEntryId, mealEntryCreation)
      val mealEntryRow = MealEntry
        .TransformableToDB(userId, profileId, mealId, mealEntry)
        .transformInto[Tables.MealEntryRow]
      mealEntryDao
        .insert(mealEntryRow)
        .map(_.transformInto[MealEntry])
    }

    override def updateMealEntry(
        userId: UserId,
        profileId: ProfileId,
        mealId: MealId,
        mealEntryId: MealEntryId,
        mealEntryUpdate: MealEntryUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[MealEntry] = {
      val findAction =
        OptionT(mealEntryDao.find(MealEntryKey(userId, profileId, mealId, mealEntryId)))
          .getOrElseF(DBIO.failed(DBError.Meal.EntryNotFound))
      for {
        mealEntryRow <- findAction
        _ <- mealEntryDao.update(
          MealEntry
            .TransformableToDB(
              userId,
              profileId,
              mealEntryRow.mealId.transformInto[MealId],
              MealEntryUpdate.update(mealEntryRow.transformInto[MealEntry], mealEntryUpdate)
            )
            .transformInto[Tables.MealEntryRow]
        )
        updatedMealEntry <- findAction
      } yield updatedMealEntry.transformInto[MealEntry]
    }

    override def removeMealEntry(
        userId: UserId,
        profileId: ProfileId,
        mealId: MealId,
        mealEntryId: MealEntryId
    )(implicit
        ec: ExecutionContext
    ): DBIO[Boolean] =
      mealEntryDao
        .delete(MealEntryKey(userId, profileId, mealId, mealEntryId))
        .map(_ > 0)

  }

}
