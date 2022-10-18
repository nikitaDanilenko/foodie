package services.recipe

import cats.data.OptionT
import cats.syntax.traverse._
import db.generated.Tables
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl.TransformerOps
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.{ IngredientId, RecipeId, UserId }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._
import java.util.UUID

import cats.Applicative
import javax.inject.Inject

import scala.concurrent.{ ExecutionContext, Future }

trait RecipeService {
  def allFoods: Future[Seq[Food]]
  def allMeasures: Future[Seq[Measure]]

  def allRecipes(userId: UserId): Future[Seq[Recipe]]
  def getRecipe(userId: UserId, id: RecipeId): Future[Option[Recipe]]
  def createRecipe(userId: UserId, recipeCreation: RecipeCreation): Future[ServerError.Or[Recipe]]
  def updateRecipe(userId: UserId, recipeUpdate: RecipeUpdate): Future[ServerError.Or[Recipe]]
  def deleteRecipe(userId: UserId, id: RecipeId): Future[Boolean]

  def getIngredients(userId: UserId, recipeId: RecipeId): Future[List[Ingredient]]
  def addIngredient(userId: UserId, ingredientCreation: IngredientCreation): Future[ServerError.Or[Ingredient]]
  def updateIngredient(userId: UserId, ingredientUpdate: IngredientUpdate): Future[ServerError.Or[Ingredient]]
  def removeIngredient(userId: UserId, ingredientId: IngredientId): Future[Boolean]
}

object RecipeService {

  trait Companion {
    def allFoods(implicit ec: ExecutionContext): DBIO[Seq[Food]]
    def allMeasures(implicit ec: ExecutionContext): DBIO[Seq[Measure]]

    def allRecipes(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[Recipe]]

    def getRecipe(
        userId: UserId,
        id: RecipeId
    )(implicit ec: ExecutionContext): DBIO[Option[Recipe]]

    def createRecipe(
        userId: UserId,
        id: RecipeId,
        recipeCreation: RecipeCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[Recipe]

    def updateRecipe(
        userId: UserId,
        recipeUpdate: RecipeUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[Recipe]

    def deleteRecipe(
        userId: UserId,
        id: RecipeId
    )(implicit ec: ExecutionContext): DBIO[Boolean]

    def getIngredients(
        userId: UserId,
        recipeId: RecipeId
    )(implicit ec: ExecutionContext): DBIO[List[Ingredient]]

    def addIngredient(
        userId: UserId,
        id: IngredientId,
        ingredientCreation: IngredientCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[Ingredient]

    def updateIngredient(
        userId: UserId,
        ingredientUpdate: IngredientUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[Ingredient]

    def removeIngredient(
        userId: UserId,
        id: IngredientId
    )(implicit ec: ExecutionContext): DBIO[Boolean]

  }

  class Live @Inject() (
      override protected val dbConfigProvider: DatabaseConfigProvider,
      companion: Companion
  )(implicit
      executionContext: ExecutionContext
  ) extends RecipeService
      with HasDatabaseConfigProvider[PostgresProfile] {

    override def allFoods: Future[Seq[Food]] = db.run(companion.allFoods)

    override def allMeasures: Future[Seq[Measure]] = db.run(companion.allMeasures)

    override def allRecipes(userId: UserId): Future[Seq[Recipe]] = db.run(companion.allRecipes(userId))

    override def getRecipe(
        userId: UserId,
        id: RecipeId
    ): Future[Option[Recipe]] =
      db.run(companion.getRecipe(userId, id))

    // TODO: The error can be specialized, because the most likely case is that the user is missing,
    // and thus a foreign key constraint is not met.
    override def createRecipe(
        userId: UserId,
        recipeCreation: RecipeCreation
    ): Future[ServerError.Or[Recipe]] = {
      db.run(companion.createRecipe(userId, UUID.randomUUID().transformInto[RecipeId], recipeCreation))
        .map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.Recipe.Creation(error.getMessage).asServerError)
        }
    }

    override def updateRecipe(
        userId: UserId,
        recipeUpdate: RecipeUpdate
    ): Future[ServerError.Or[Recipe]] =
      db.run(companion.updateRecipe(userId, recipeUpdate))
        .map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.Recipe.Update(error.getMessage).asServerError)
        }

    override def deleteRecipe(
        userId: UserId,
        id: RecipeId
    ): Future[Boolean] = db.run(companion.deleteRecipe(userId, id))

    override def getIngredients(userId: UserId, recipeId: RecipeId): Future[List[Ingredient]] =
      db.run(companion.getIngredients(userId, recipeId))

    override def addIngredient(
        userId: UserId,
        ingredientCreation: IngredientCreation
    ): Future[ServerError.Or[Ingredient]] =
      db.run(companion.addIngredient(userId, UUID.randomUUID().transformInto[IngredientId], ingredientCreation))
        .map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.Recipe.Ingredient.Creation(error.getMessage).asServerError)
        }

    override def updateIngredient(
        userId: UserId,
        ingredientUpdate: IngredientUpdate
    ): Future[ServerError.Or[Ingredient]] =
      db.run(companion.updateIngredient(userId, ingredientUpdate))
        .map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.Recipe.Ingredient.Update(error.getMessage).asServerError)
        }

    override def removeIngredient(userId: UserId, ingredientId: IngredientId): Future[Boolean] =
      db.run(companion.removeIngredient(userId, ingredientId))

  }

  object Live extends Companion {

    override def allFoods(implicit ec: ExecutionContext): DBIO[Seq[Food]] =
      for {
        foods <- Tables.FoodName.result
        withMeasure <- foods.traverse { food =>
          Tables.ConversionFactor
            .filter(cf => cf.foodId === food.foodId)
            .map(_.measureId)
            .result
            .flatMap(measureIds =>
              Tables.MeasureName.filter(_.measureId.inSetBind(measureIds)).result.map(ms => food -> ms.toList)
            ): DBIO[(Tables.FoodNameRow, List[Tables.MeasureNameRow])]
        }
      } yield withMeasure.map(_.transformInto[Food])

    override def allMeasures(implicit ec: ExecutionContext): DBIO[Seq[Measure]] =
      Tables.MeasureName.result
        .map(_.map(_.transformInto[Measure]))

    override def allRecipes(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[Recipe]] =
      Tables.Recipe
        .filter(_.userId === userId.transformInto[UUID])
        .result
        .map(
          _.map(_.transformInto[Recipe])
        )

    override def getRecipe(userId: UserId, id: RecipeId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[Recipe]] =
      OptionT(
        recipeQuery(userId, id).result.headOption: DBIO[Option[Tables.RecipeRow]]
      ).map(_.transformInto[Recipe]).value

    override def createRecipe(
        userId: UserId,
        id: RecipeId,
        recipeCreation: RecipeCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[Recipe] = {
      val recipe    = RecipeCreation.create(id, recipeCreation)
      val recipeRow = (recipe, userId).transformInto[Tables.RecipeRow]
      (Tables.Recipe.returning(Tables.Recipe) += recipeRow)
        .map(_.transformInto[Recipe])
    }

    override def updateRecipe(
        userId: UserId,
        recipeUpdate: RecipeUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[Recipe] = {
      val findAction = OptionT(getRecipe(userId, recipeUpdate.id)).getOrElseF(DBIO.failed(DBError.RecipeNotFound))
      for {
        recipe <- findAction
        _ <- recipeQuery(userId, recipeUpdate.id).update(
          (
            RecipeUpdate
              .update(recipe, recipeUpdate),
            userId
          )
            .transformInto[Tables.RecipeRow]
        )
        updatedRecipe <- findAction
      } yield updatedRecipe
    }

    override def deleteRecipe(userId: UserId, id: RecipeId)(implicit
        ec: ExecutionContext
    ): DBIO[Boolean] =
      recipeQuery(userId, id).delete
        .map(_ > 0)

    override def getIngredients(
        userId: UserId,
        recipeId: RecipeId
    )(implicit
        ec: ExecutionContext
    ): DBIO[List[Ingredient]] =
      for {
        exists <- recipeQuery(userId, recipeId).exists.result
        ingredients <-
          if (exists)
            Tables.RecipeIngredient
              .filter(_.recipeId === recipeId.transformInto[UUID])
              .result
              .map(_.map(_.transformInto[Ingredient]).toList)
          else Applicative[DBIO].pure(List.empty)
      } yield ingredients

    override def addIngredient(
        userId: UserId,
        id: IngredientId,
        ingredientCreation: IngredientCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[Ingredient] = {
      val ingredient    = IngredientCreation.create(id, ingredientCreation)
      val ingredientRow = (ingredient, ingredientCreation.recipeId).transformInto[Tables.RecipeIngredientRow]
      val query         = ingredientQuery(id)
      ifRecipeExists(userId, ingredientCreation.recipeId) {
        for {
          exists <- query.exists.result
          row <-
            if (exists)
              query
                .update(ingredientRow)
                .andThen(query.result.head)
            else
              Tables.RecipeIngredient.returning(Tables.RecipeIngredient) += ingredientRow
        } yield row.transformInto[Ingredient]
      }
    }

    override def updateIngredient(
        userId: UserId,
        ingredientUpdate: IngredientUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[Ingredient] = {
      val findAction =
        OptionT(ingredientQuery(ingredientUpdate.id).result.headOption: DBIO[Option[Tables.RecipeIngredientRow]])
          .getOrElseF(DBIO.failed(DBError.RecipeIngredientNotFound))
      for {
        ingredientRow <- findAction
        _ <- ingredientQuery(ingredientUpdate.id).update(
          (
            IngredientUpdate
              .update(ingredientRow.transformInto[Ingredient], ingredientUpdate),
            ingredientRow.recipeId.transformInto[RecipeId]
          )
            .transformInto[Tables.RecipeIngredientRow]
        )
        updatedIngredientRow <- findAction
      } yield updatedIngredientRow.transformInto[Ingredient]
    }

    override def removeIngredient(
        userId: UserId,
        id: IngredientId
    )(implicit ec: ExecutionContext): DBIO[Boolean] = {
      OptionT(
        ingredientQuery(id)
          .map(_.recipeId)
          .result
          .headOption: DBIO[Option[UUID]]
      )
        .semiflatMap(recipeId =>
          ifRecipeExists(userId, recipeId.transformInto[RecipeId]) {
            ingredientQuery(id).delete
              .map(_ > 0)
          }
        )
        .getOrElse(false)
    }

    private def recipeQuery(
        userId: UserId,
        id: RecipeId
    ): Query[Tables.Recipe, Tables.RecipeRow, Seq] =
      Tables.Recipe
        .filter(r =>
          r.id === id.transformInto[UUID] &&
            r.userId === userId.transformInto[UUID]
        )

    private def ingredientQuery(
        ingredientId: IngredientId
    ): Query[Tables.RecipeIngredient, Tables.RecipeIngredientRow, Seq] =
      Tables.RecipeIngredient
        .filter(_.id === ingredientId.transformInto[UUID])

    private def ifRecipeExists[A](
        userId: UserId,
        id: RecipeId
    )(action: => DBIO[A])(implicit ec: ExecutionContext): DBIO[A] =
      recipeQuery(userId, id).exists.result.flatMap(exists => if (exists) action else notFound)

    private def notFound[A]: DBIO[A] = DBIO.failed(DBError.RecipeNotFound)
  }

}
