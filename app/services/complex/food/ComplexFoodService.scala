package services.complex.food

import cats.data.OptionT
import db.generated.Tables
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.recipe.RecipeService
import services.{ DBError, RecipeId, UserId }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

trait ComplexFoodService {

  def all(userId: UserId): Future[Seq[ComplexFood]]

  def get(userId: UserId, recipeId: RecipeId): Future[Option[ComplexFood]]

  def create(
      userId: UserId,
      complexFood: ComplexFood
  ): Future[ServerError.Or[ComplexFood]]

  def update(
      userId: UserId,
      complexFood: ComplexFood
  ): Future[ServerError.Or[ComplexFood]]

  def delete(userId: UserId, recipeId: RecipeId): Future[Boolean]

}

object ComplexFoodService {

  trait Companion {
    def all(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[ComplexFood]]

    def get(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Option[ComplexFood]]

    def create(
        userId: UserId,
        complexFood: ComplexFood
    )(implicit ec: ExecutionContext): DBIO[ComplexFood]

    def update(
        userId: UserId,
        complexFood: ComplexFood
    )(implicit ec: ExecutionContext): DBIO[ComplexFood]

    def delete(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Boolean]
  }

  class Live @Inject() (
      override protected val dbConfigProvider: DatabaseConfigProvider,
      companion: Companion
  )(implicit ec: ExecutionContext)
      extends ComplexFoodService
      with HasDatabaseConfigProvider[PostgresProfile] {

    override def all(userId: UserId): Future[Seq[ComplexFood]] =
      db.run(companion.all(userId))

    override def get(userId: UserId, recipeId: RecipeId): Future[Option[ComplexFood]] =
      db.run(companion.get(userId, recipeId))

    override def create(
        userId: UserId,
        complexFood: ComplexFood
    ): Future[ServerError.Or[ComplexFood]] =
      db.run(companion.create(userId, complexFood))
        .map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.ComplexFood.Creation(error.getMessage).asServerError)
        }

    override def update(
        userId: UserId,
        complexFood: ComplexFood
    ): Future[ServerError.Or[ComplexFood]] =
      db.run(companion.update(userId, complexFood))
        .map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.ComplexFood.Update(error.getMessage).asServerError)
        }

    override def delete(userId: UserId, recipeId: RecipeId): Future[Boolean] =
      db.run(companion.delete(userId, recipeId))

  }

  object Live extends Companion {

    override def all(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[ComplexFood]] =
      for {
        recipeIds <- Tables.Recipe.filter(_.userId === userId.transformInto[UUID]).map(_.id).result
        complex   <- Tables.ComplexFood.filter(_.recipeId.inSetBind(recipeIds)).result
      } yield complex.map(_.transformInto[ComplexFood])

    override def get(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Option[ComplexFood]] =
      for {
        exists <- RecipeService.Live.getRecipe(userId, recipeId).map(_.isDefined)
        result <-
          if (exists) Tables.ComplexFood.filter(_.recipeId === recipeId.transformInto[UUID]).result.headOption
          else DBIO.successful(None)
      } yield result.map(_.transformInto[ComplexFood])

    override def create(userId: UserId, complexFood: ComplexFood)(implicit
        ec: ExecutionContext
    ): DBIO[ComplexFood] = {
      val query          = complexFoodQuery(complexFood.recipeId)
      val complexFoodRow = complexFood.transformInto[Tables.ComplexFoodRow]
      ifRecipeExists(userId, complexFood.recipeId) {
        for {
          exists <- query.exists.result
          row <-
            if (exists)
              query
                .update(complexFoodRow)
                .andThen(query.result.head)
            else Tables.ComplexFood.returning(Tables.ComplexFood) += complexFoodRow
        } yield row.transformInto[ComplexFood]
      }
    }

    override def update(userId: UserId, complexFood: ComplexFood)(implicit
        ec: ExecutionContext
    ): DBIO[ComplexFood] = {
      val findAction =
        OptionT(get(userId, complexFood.recipeId))
          .getOrElseF(DBIO.failed(DBError.Complex.Food.NotFound))
      for {
        _ <- findAction
        _ <- complexFoodQuery(complexFood.recipeId)
          .update(complexFood.transformInto[Tables.ComplexFoodRow])
        updatedFood <- findAction
      } yield updatedFood
    }

    override def delete(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Boolean] =
      complexFoodQuery(recipeId).delete
        .map(_ > 0)

    private def ifRecipeExists[A](
        userId: UserId,
        recipeId: RecipeId
    )(action: => DBIO[A])(implicit ec: ExecutionContext): DBIO[A] =
      RecipeService.Live
        .getRecipe(userId, recipeId)
        .map(_.isDefined)
        .flatMap(exists => if (exists) action else DBIO.failed(DBError.Complex.Food.RecipeNotFound))

    private def complexFoodQuery(
        recipeId: RecipeId
    ): Query[Tables.ComplexFood, Tables.ComplexFoodRow, Seq] =
      Tables.ComplexFood.filter(_.recipeId === recipeId.transformInto[UUID])

  }

}
