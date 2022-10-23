package services.complex.ingredient

import cats.Applicative
import cats.data.OptionT
import db.generated.Tables
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.recipe.RecipeService
import services.{ ComplexFoodId, DBError, RecipeId, UserId }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

trait ComplexIngredientService {

  def all(userId: UserId, recipeId: RecipeId): Future[Seq[ComplexIngredient]]

  def create(
      userId: UserId,
      complexIngredient: ComplexIngredient
  ): Future[ServerError.Or[ComplexIngredient]]

  def update(
      userId: UserId,
      complexIngredient: ComplexIngredient
  ): Future[ServerError.Or[ComplexIngredient]]

  def delete(userId: UserId, recipeId: RecipeId, complexFoodId: ComplexFoodId): Future[Boolean]

}

object ComplexIngredientService {

  trait Companion {
    def all(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Seq[ComplexIngredient]]

    def create(
        userId: UserId,
        complexIngredient: ComplexIngredient
    )(implicit ec: ExecutionContext): DBIO[ComplexIngredient]

    def update(
        userId: UserId,
        complexIngredient: ComplexIngredient
    )(implicit ec: ExecutionContext): DBIO[ComplexIngredient]

    def delete(userId: UserId, recipeId: RecipeId, complexFoodId: ComplexFoodId)(implicit
        ec: ExecutionContext
    ): DBIO[Boolean]

  }

  class Live @Inject() (
      override protected val dbConfigProvider: DatabaseConfigProvider,
      companion: Companion
  )(implicit ec: ExecutionContext)
      extends ComplexIngredientService
      with HasDatabaseConfigProvider[PostgresProfile] {

    override def all(userId: UserId, recipeId: RecipeId): Future[Seq[ComplexIngredient]] =
      db.run(companion.all(userId, recipeId))

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

    override def delete(userId: UserId, recipeId: RecipeId, complexFoodId: ComplexFoodId): Future[Boolean] =
      db.run(companion.delete(userId, recipeId, complexFoodId))

  }

  object Live extends Companion {

    override def all(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Seq[ComplexIngredient]] =
      for {
        exists <- RecipeService.Live.getRecipe(userId, recipeId).map(_.isDefined)
        complexIngredients <-
          if (exists)
            Tables.ComplexIngredient
              .filter(_.recipeId === recipeId.transformInto[UUID])
              .result
          else Applicative[DBIO].pure(List.empty)
      } yield complexIngredients.map(_.transformInto[ComplexIngredient])

    override def create(userId: UserId, complexIngredient: ComplexIngredient)(implicit
        ec: ExecutionContext
    ): DBIO[ComplexIngredient] = {
      val query = complexIngredientQuery(
        userId = userId,
        recipeId = complexIngredient.recipeId,
        complexFoodId = complexIngredient.complexFoodId
      )
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
      val query = complexIngredientQuery(
        userId = userId,
        recipeId = complexIngredient.recipeId,
        complexFoodId = complexIngredient.complexFoodId
      )
      val findAction =
        OptionT(
          query.result.headOption: DBIO[Option[Tables.ComplexIngredientRow]]
        )
          .getOrElseF(DBIO.failed(DBError.Complex.Ingredient.NotFound))
      for {
        _ <- findAction
        _ <-
          query
            .update(complexIngredient.transformInto[Tables.ComplexIngredientRow])
        updatedIngredient <- findAction
      } yield updatedIngredient.transformInto[ComplexIngredient]
    }

    override def delete(userId: UserId, recipeId: RecipeId, complexFoodId: ComplexFoodId)(implicit
        ec: ExecutionContext
    ): DBIO[Boolean] =
      complexIngredientQuery(userId, recipeId, complexFoodId).delete
        .map(_ > 0)

    private def ifRecipeExists[A](
        userId: UserId,
        recipeId: RecipeId
    )(action: => DBIO[A])(implicit ec: ExecutionContext): DBIO[A] =
      RecipeService.Live
        .getRecipe(userId, recipeId)
        .map(_.isDefined)
        .flatMap(exists => if (exists) action else DBIO.failed(DBError.Complex.Ingredient.RecipeNotFound))

    private def complexIngredientQuery(
        userId: UserId,
        recipeId: RecipeId,
        complexFoodId: ComplexFoodId
    ): Query[Tables.ComplexIngredient, Tables.ComplexIngredientRow, Seq] =
      for {
        // Guard: If the query is empty, the second filter is not applied
        _ <-
          Tables.Recipe
            .filter(recipe =>
              recipe.userId === userId.transformInto[UUID] &&
                recipe.id === recipeId.transformInto[UUID]
            )
        complexIngredients <- Tables.ComplexIngredient.filter(ingredient =>
          ingredient.recipeId === recipeId.transformInto[UUID] &&
            ingredient.complexFoodId === complexFoodId.transformInto[UUID]
        )
      } yield complexIngredients

  }

}
