package services.duplication.meal

import cats.data.OptionT
import db.daos.meal.MealKey
import db.generated.Tables
import db.{ MealEntryId, MealId, ProfileId, UserId }
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.common.Transactionally.syntax._
import services.meal.{ Meal, MealCreation, MealEntry, MealService }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._
import utils.date.SimpleDate

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

class Live @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider,
    companion: Duplication.Companion,
    mealServiceCompanion: MealService.Companion
)(implicit
    executionContext: ExecutionContext
) extends Duplication
    with HasDatabaseConfigProvider[PostgresProfile] {

  override def duplicate(
      userId: UserId,
      profileId: ProfileId,
      id: MealId,
      timeOfDuplication: SimpleDate
  ): Future[ServerError.Or[Meal]] = {
    val action = for {
      mealEntries <- mealServiceCompanion
        .getMealEntries(userId, profileId, Seq(id))
        .map(_.getOrElse(MealKey(userId, profileId, id), Seq.empty))
      newMealEntries = mealEntries.map { mealEntry =>
        Duplication.DuplicatedMealEntry(
          mealEntry = mealEntry,
          newId = UUID.randomUUID().transformInto[MealEntryId]
        )
      }
      newMealId = UUID.randomUUID().transformInto[MealId]
      newMeal <- companion.duplicateMeal(
        userId = userId,
        profileId = profileId,
        id = id,
        newId = newMealId,
        timestamp = timeOfDuplication
      )
      _ <- companion.duplicateMealEntries(userId, profileId, newMealId, newMealEntries)
    } yield newMeal

    db.runTransactionally(action)
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Meal.Creation(error.getMessage).asServerError)
      }
  }

}

object Live {

  class Companion @Inject() (
      mealServiceCompanion: MealService.Companion,
      mealEntryDao: db.daos.mealEntry.DAO
  ) extends Duplication.Companion {

    override def duplicateMeal(
        userId: UserId,
        profileId: ProfileId,
        id: MealId,
        newId: MealId,
        timestamp: SimpleDate
    )(implicit
        ec: ExecutionContext
    ): DBIO[Meal] = {
      val transformer = for {
        meal <- OptionT(mealServiceCompanion.getMeal(userId, profileId, id))
        inserted <- OptionT.liftF(
          mealServiceCompanion.createMeal(
            userId = userId,
            profileId = profileId,
            mealId = newId,
            mealCreation = MealCreation(
              date = timestamp,
              name =
                Some(s"${meal.name.fold("")(name => s"$name ")}(copy from ${SimpleDate.toPrettyString(meal.date)})")
            )
          )
        )
      } yield inserted

      transformer.getOrElseF(mealServiceCompanion.notFound)
    }

    override def duplicateMealEntries(
        userId: UserId,
        profileId: ProfileId,
        newMealId: MealId,
        mealEntries: Seq[Duplication.DuplicatedMealEntry]
    )(implicit
        ec: ExecutionContext
    ): DBIO[Seq[MealEntry]] =
      mealEntryDao
        .insertAll {
          mealEntries.map { duplicatedMealEntry =>
            val newMealEntry = duplicatedMealEntry.mealEntry.copy(id = duplicatedMealEntry.newId)
            MealEntry.TransformableToDB(userId, profileId, newMealId, newMealEntry).transformInto[Tables.MealEntryRow]
          }
        }
        .map(_.map(_.transformInto[MealEntry]))

  }

}
