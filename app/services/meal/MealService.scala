package services.meal

import cats.data.OptionT
import cats.syntax.traverse._
import db.generated.Tables
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl.TransformerOps
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.{ MealEntryId, MealId, UserId }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

trait MealService {
  def allMeals(userId: UserId, interval: RequestInterval): Future[Seq[Meal]]
  def getMeal(userId: UserId, id: MealId): Future[Option[Meal]]

  def createMeal(userId: UserId, mealCreation: MealCreation): Future[ServerError.Or[Meal]]
  def updateMeal(userId: UserId, mealUpdate: MealUpdate): Future[ServerError.Or[Meal]]
  def deleteMeal(userId: UserId, id: MealId): Future[Boolean]

  def addMealEntry(userId: UserId, mealEntryCreation: MealEntryCreation): Future[ServerError.Or[MealEntry]]
  def updateMealEntry(userId: UserId, mealEntryUpdate: MealEntryUpdate): Future[ServerError.Or[MealEntry]]
  def removeMealEntry(userId: UserId, mealEntryId: MealEntryId): Future[Boolean]
}

object MealService {

  trait Companion {
    def allMeals(userId: UserId, interval: RequestInterval)(implicit ec: ExecutionContext): DBIO[Seq[Meal]]
    def getMeal(userId: UserId, id: MealId)(implicit ec: ExecutionContext): DBIO[Option[Meal]]

    def createMeal(userId: UserId, id: MealId, mealCreation: MealCreation)(implicit ec: ExecutionContext): DBIO[Meal]
    def updateMeal(userId: UserId, mealUpdate: MealUpdate)(implicit ec: ExecutionContext): DBIO[Meal]
    def deleteMeal(userId: UserId, id: MealId)(implicit ec: ExecutionContext): DBIO[Boolean]

    def addMealEntry(
        userId: UserId,
        id: MealEntryId,
        mealEntryCreation: MealEntryCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[MealEntry]

    def updateMealEntry(
        userId: UserId,
        mealEntryUpdate: MealEntryUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[MealEntry]

    def removeMealEntry(
        userId: UserId,
        id: MealEntryId
    )(implicit ec: ExecutionContext): DBIO[Boolean]

  }

  class Live @Inject() (
      override protected val dbConfigProvider: DatabaseConfigProvider,
      companion: Companion
  )(implicit
      executionContext: ExecutionContext
  ) extends MealService
      with HasDatabaseConfigProvider[PostgresProfile] {

    override def allMeals(userId: UserId, interval: RequestInterval): Future[Seq[Meal]] =
      db.run(companion.allMeals(userId, interval))

    override def getMeal(userId: UserId, id: MealId): Future[Option[Meal]] = db.run(companion.getMeal(userId, id))

    // TODO: The error can be specialized, because the most likely case is that the user is missing,
    // and thus a foreign key constraint is not met.
    override def createMeal(userId: UserId, mealCreation: MealCreation): Future[ServerError.Or[Meal]] =
      db.run(companion.createMeal(userId, UUID.randomUUID().transformInto[MealId], mealCreation))
        .map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.Meal.Creation(error.getMessage).asServerError)
        }

    override def updateMeal(userId: UserId, mealUpdate: MealUpdate): Future[ServerError.Or[Meal]] =
      db.run(companion.updateMeal(userId, mealUpdate))
        .map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.Meal.Update(error.getMessage).asServerError)
        }

    override def deleteMeal(userId: UserId, id: MealId): Future[Boolean] = db.run(companion.deleteMeal(userId, id))

    override def addMealEntry(userId: UserId, mealEntryCreation: MealEntryCreation): Future[ServerError.Or[MealEntry]] =
      db.run(companion.addMealEntry(userId, UUID.randomUUID().transformInto[MealEntryId], mealEntryCreation))
        .map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.Meal.Entry.Creation(error.getMessage).asServerError)
        }

    override def updateMealEntry(userId: UserId, mealEntryUpdate: MealEntryUpdate): Future[ServerError.Or[MealEntry]] =
      db.run(companion.updateMealEntry(userId, mealEntryUpdate))
        .map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.Meal.Entry.Update(error.getMessage).asServerError)
        }

    override def removeMealEntry(userId: UserId, mealEntryId: MealEntryId): Future[Boolean] =
      db.run(companion.removeMealEntry(userId, mealEntryId))

  }

  object Live extends Companion {

    override def allMeals(
        userId: UserId,
        interval: RequestInterval
    )(implicit
        ec: ExecutionContext
    ): DBIO[Seq[Meal]] = {
      val dateFilter: Rep[java.sql.Date] => Rep[Boolean] = DBIOUtil.dateFilter(interval.from, interval.to)

      Tables.Meal
        .filter(m => m.userId === userId.transformInto[UUID] && dateFilter(m.consumedOnDate))
        .map(_.id)
        .result
        .flatMap(
          _.traverse(id => getMeal(userId, id.transformInto[MealId]))
        )
        .map(_.flatten)
    }

    override def getMeal(
        userId: UserId,
        id: MealId
    )(implicit ec: ExecutionContext): DBIO[Option[Meal]] = {
      val transformer = for {
        mealRow <- OptionT(
          mealQuery(userId, id).result.headOption: DBIO[Option[Tables.MealRow]]
        )
        mealEntryRows <- OptionT.liftF(
          Tables.MealEntry
            .filter(_.mealId === id.transformInto[UUID])
            .result: DBIO[Seq[Tables.MealEntryRow]]
        )
      } yield Meal
        .DBRepresentation(
          mealRow = mealRow,
          mealEntryRows = mealEntryRows
        )
        .transformInto[Meal]

      transformer.value
    }

    override def createMeal(
        userId: UserId,
        id: MealId,
        mealCreation: MealCreation
    )(implicit ec: ExecutionContext): DBIO[Meal] = {
      val meal             = MealCreation.create(id, mealCreation)
      val dbRepresentation = (meal, userId).transformInto[Meal.DBRepresentation]
      (Tables.Meal.returning(Tables.Meal) += dbRepresentation.mealRow)
        .map { mealRow =>
          dbRepresentation
            .copy(mealRow = mealRow)
            .transformInto[Meal]
        }
    }

    override def updateMeal(
        userId: UserId,
        mealUpdate: MealUpdate
    )(implicit ec: ExecutionContext): DBIO[Meal] = {
      val findAction = OptionT(getMeal(userId, mealUpdate.id))
        .getOrElseF(DBIO.failed(DBError.MealNotFound))

      for {
        meal <- findAction
        _ <- mealQuery(userId, mealUpdate.id).update(
          (
            MealUpdate
              .update(meal, mealUpdate),
            userId
          )
            .transformInto[Meal.DBRepresentation]
            .mealRow
        )
        updatedMeal <- findAction
      } yield updatedMeal
    }

    override def deleteMeal(
        userId: UserId,
        id: MealId
    )(implicit ec: ExecutionContext): DBIO[Boolean] =
      mealQuery(userId, id).delete
        .map(_ > 0)

    override def addMealEntry(
        userId: UserId,
        id: MealEntryId,
        mealEntryCreation: MealEntryCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[MealEntry] = {
      val mealEntry = MealEntryCreation.create(id, mealEntryCreation)
      ifMealExists(userId, mealEntryCreation.mealId) {
        (Tables.MealEntry
          .returning(Tables.MealEntry) += (mealEntry, mealEntryCreation.mealId)
          .transformInto[Tables.MealEntryRow])
          .map(_.transformInto[MealEntry])
      }
    }

    override def updateMealEntry(
        userId: UserId,
        mealEntryUpdate: MealEntryUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[MealEntry] = {
      val findAction = OptionT(mealEntryQuery(mealEntryUpdate.id).result.headOption: DBIO[Option[Tables.MealEntryRow]])
        .getOrElseF(DBIO.failed(DBError.MealEntryNotFound))
      for {
        mealEntryRow <- findAction
        _ <- mealEntryQuery(mealEntryUpdate.id).update(
          (
            MealEntryUpdate
              .update(mealEntryRow.transformInto[MealEntry], mealEntryUpdate),
            mealEntryRow.mealId.transformInto[MealId]
          )
            .transformInto[Tables.MealEntryRow]
        )
        updatedMealEntry <- findAction
      } yield updatedMealEntry.transformInto[MealEntry]
    }

    override def removeMealEntry(
        userId: UserId,
        id: MealEntryId
    )(implicit
        ec: ExecutionContext
    ): DBIO[Boolean] =
      OptionT(
        mealEntryQuery(id)
          .map(_.mealId)
          .result
          .headOption: DBIO[Option[UUID]]
      )
        .semiflatMap(mealId =>
          ifMealExists(userId, mealId.transformInto[MealId]) {
            mealEntryQuery(id).delete
              .map(_ > 0)
          }
        )
        .getOrElse(false)

    private def mealQuery(
        userId: UserId,
        id: MealId
    ): Query[Tables.Meal, Tables.MealRow, Seq] =
      Tables.Meal
        .filter(r =>
          r.id === id.transformInto[UUID] &&
            r.userId === userId.transformInto[UUID]
        )

    private def mealEntryQuery(
        mealEntryId: MealEntryId
    ): Query[Tables.MealEntry, Tables.MealEntryRow, Seq] =
      Tables.MealEntry
        .filter(_.id === mealEntryId.transformInto[UUID])

    private def ifMealExists[A](
        userId: UserId,
        id: MealId
    )(action: => DBIO[A])(implicit ec: ExecutionContext): DBIO[A] =
      mealQuery(userId, id).exists.result.flatMap(exists => if (exists) action else notFound)

    private def notFound[A]: DBIO[A] = DBIO.failed(DBError.MealNotFound)

  }

}
