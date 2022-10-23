package services.complex

import cats.data.OptionT
import db.generated.Tables
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.recipe.RecipeService
import services.{ RecipeId, UserId }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

trait ComplexIngredientService {

  def all(userId: UserId): Future[Seq[ComplexIngredient]]

  def get(userId: UserId, id: RecipeId): Future[Option[ComplexIngredient]]

  def create(
      userId: UserId,
      complexIngredient: ComplexIngredient
  ): Future[ServerError.Or[ComplexIngredient]]

  def update(
      userId: UserId,
      complexIngredient: ComplexIngredient
  ): Future[ServerError.Or[ComplexIngredient]]

  def delete(userId: UserId, id: RecipeId): Future[Boolean]

}

object ComplexIngredientService {

  trait Companion {
    def all(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[ComplexIngredient]]

    def get(userId: UserId, id: RecipeId)(implicit ec: ExecutionContext): DBIO[Option[ComplexIngredient]]

    def create(
        userId: UserId,
        complexIngredient: ComplexIngredient
    )(implicit ec: ExecutionContext): DBIO[ComplexIngredient]

    def update(
        userId: UserId,
        complexIngredient: ComplexIngredient
    )(implicit ec: ExecutionContext): DBIO[ComplexIngredient]

    def delete(userId: UserId, id: RecipeId)(implicit ec: ExecutionContext): DBIO[Boolean]
  }

  class Live @Inject() (
      override protected val dbConfigProvider: DatabaseConfigProvider,
      companion: Companion
  )(implicit ec: ExecutionContext)
      extends ComplexIngredientService
      with HasDatabaseConfigProvider[PostgresProfile] {

    override def all(userId: UserId): Future[Seq[ComplexIngredient]] =
      db.run(companion.all(userId))

    override def get(userId: UserId, id: RecipeId): Future[Option[ComplexIngredient]] =
      db.run(companion.get(userId, id))

    override def create(
        userId: UserId,
        complexIngredient: ComplexIngredient
    ): Future[ServerError.Or[ComplexIngredient]] =
      db.run(companion.create(userId, complexIngredient))
        .map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.Recipe.ComplexIngredient.Creation(error.getMessage).asServerError)
        }

    override def update(
        userId: UserId,
        complexIngredient: ComplexIngredient
    ): Future[ServerError.Or[ComplexIngredient]] =
      db.run(companion.update(userId, complexIngredient))
        .map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.Recipe.ComplexIngredient.Update(error.getMessage).asServerError)
        }

    override def delete(userId: UserId, id: RecipeId): Future[Boolean] =
      db.run(companion.delete(userId, id))

  }

  object Live extends Companion {

    override def all(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[ComplexIngredient]] =
      for {
        recipeIds <- Tables.Recipe.filter(_.userId === userId.transformInto[UUID]).map(_.id).result
        complex   <- Tables.ComplexIngredient.filter(_.recipeId.inSetBind(recipeIds)).result
      } yield complex.map(_.transformInto[ComplexIngredient])

    override def get(userId: UserId, id: RecipeId)(implicit ec: ExecutionContext): DBIO[Option[ComplexIngredient]] =
      for {
        exists <- RecipeService.Live.getRecipe(userId, id).map(_.isDefined)
        result <-
          if (exists) Tables.ComplexIngredient.filter(_.recipeId === id.transformInto[UUID]).result.headOption
          else DBIO.successful(None)
      } yield result.map(_.transformInto[ComplexIngredient])

    override def create(userId: UserId, complexIngredient: ComplexIngredient)(implicit
        ec: ExecutionContext
    ): DBIO[ComplexIngredient] = {
      val query                = complexIngredientQuery(userId, complexIngredient.recipeId)
      val complexIngredientRow = complexIngredient.transformInto[Tables.ComplexIngredientRow]
      ifRecipeExists(userId, complexIngredient.recipeId) {
        for {
          exists <- query.exists.result
          row <-
            if (exists)
              query
                .update(complexIngredientRow)
                .andThen(query.result.head)
            else Tables.ComplexIngredient.returning(Tables.ComplexIngredient) += complexIngredientRow
        } yield row.transformInto[ComplexIngredient]
      }
    }

    override def update(userId: UserId, complexIngredient: ComplexIngredient)(implicit
        ec: ExecutionContext
    ): DBIO[ComplexIngredient] = {
      val findAction =
        OptionT(get(userId, complexIngredient.recipeId))
          .getOrElseF(DBIO.failed(DBError.ComplexIngredientNotFound))
      for {
        complexIngredient <- findAction
        _ <- complexIngredientQuery(userId, complexIngredient.recipeId)
          .update(complexIngredient.transformInto[Tables.ComplexIngredientRow])
        updatedIngredient <- findAction
      } yield updatedIngredient
    }

    override def delete(userId: UserId, id: RecipeId)(implicit ec: ExecutionContext): DBIO[Boolean] =
      complexIngredientQuery(userId, id).delete
        .map(_ > 0)

    private def ifRecipeExists[A](
        userId: UserId,
        id: RecipeId
    )(action: => DBIO[A])(implicit ec: ExecutionContext): DBIO[A] =
      RecipeService.Live
        .getRecipe(userId, id)
        .map(_.isDefined)
        .flatMap(exists => if (exists) action else DBIO.failed(DBError.RecipeNotFound))

    private def complexIngredientQuery(
        userId: UserId,
        id: RecipeId
    ): Query[Tables.ComplexIngredient, Tables.ComplexIngredientRow, Seq] =
      for {
        // Guard: If the query is empty, the second filter is not applied
        _ <-
          Tables.Recipe
            .filter(recipe =>
              recipe.userId === userId.transformInto[UUID] &&
                recipe.id === id.transformInto[UUID]
            )
        complexIngredients <- Tables.ComplexIngredient.filter(_.recipeId === id.transformInto[UUID])
      } yield complexIngredients

  }

}
