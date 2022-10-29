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
import utils.CycleCheck
import utils.CycleCheck.Arc
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
        recipeId = complexIngredient.recipeId,
        complexFoodId = complexIngredient.complexFoodId
      )
      val complexIngredientRow = complexIngredient.transformInto[Tables.ComplexIngredientRow]
      ifRecipeExists(userId, complexIngredient.recipeId) {
        for {
          createsCycle <- cycleCheck(complexIngredient.recipeId, complexIngredient.complexFoodId)
          _            <- if (!createsCycle) DBIO.successful(()) else DBIO.failed(DBError.Complex.Ingredient.Cycle)
          exists       <- query.exists.result
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
      complexIngredientQuery(recipeId, complexFoodId).delete
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
        recipeId: RecipeId,
        complexFoodId: ComplexFoodId
    ): Query[Tables.ComplexIngredient, Tables.ComplexIngredientRow, Seq] =
      Tables.ComplexIngredient.filter(ingredient =>
        ingredient.recipeId === recipeId.transformInto[UUID] &&
          ingredient.complexFoodId === complexFoodId.transformInto[UUID]
      )

    private def cycleCheck(recipeId: RecipeId, newReferenceRecipeId: RecipeId)(implicit
        ec: ExecutionContext
    ): DBIO[Boolean] = {
      val action =
        sql"""with recursive transitive_references as (
                select recipe_id, complex_food_id
                from complex_ingredient
                where recipe_id = ${newReferenceRecipeId.toString} :: uuid
                  union
                    select ci.recipe_id, ci.complex_food_id
                      from complex_ingredient ci
                      inner join transitive_references r on r.complex_food_id = ci.recipe_id
              )
                select recipe_id, complex_food_id from transitive_references;"""
          .as[(String, String)]

      action.map { rows =>
        val graph = CycleCheck.fromArcs(Arc(recipeId.toString, newReferenceRecipeId.toString) +: rows.map {
          case (s1, s2) => Arc(s1, s2)
        })
        CycleCheck.onCycle(recipeId.toString, graph)
      }

    }

  }

}
