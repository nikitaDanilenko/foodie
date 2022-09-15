package services.stats

import java.util.UUID

import cats.data.OptionT
import cats.syntax.traverse._
import db.generated.Tables
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl.TransformerOps
import javax.inject.Inject
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.meal.{ MealEntry, MealService }
import services.nutrient.{ Nutrient, NutrientMap, NutrientService }
import services.recipe.{ Recipe, RecipeService }
import services.{ MealId, NutrientCode, UserId }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import spire.implicits._
import utils.DBIOUtil
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._
import utils.collection.MapUtil

import scala.concurrent.{ ExecutionContext, Future }

trait StatsService {

  def nutrientsOverTime(userId: UserId, requestInterval: RequestInterval): Future[Stats]

  def referenceNutrientMap(userId: UserId): Future[Option[NutrientMap]]

  def createReferenceNutrient(
      userId: UserId,
      referenceNutrientCreation: ReferenceNutrientCreation
  ): Future[ServerError.Or[ReferenceNutrient]]

  def updateReferenceNutrient(
      userId: UserId,
      referenceNutrientUpdate: ReferenceNutrientUpdate
  ): Future[ServerError.Or[ReferenceNutrient]]

  def deleteReferenceNutrient(
      userId: UserId,
      nutrientCode: NutrientCode
  ): Future[Boolean]

}

object StatsService {

  class Live @Inject() (
      override protected val dbConfigProvider: DatabaseConfigProvider,
      companion: Companion
  )(implicit
      ec: ExecutionContext
  ) extends StatsService
      with HasDatabaseConfigProvider[PostgresProfile] {

    override def nutrientsOverTime(userId: UserId, requestInterval: RequestInterval): Future[Stats] =
      db.run(companion.nutrientsOverTime(userId, requestInterval))

    override def referenceNutrientMap(userId: UserId): Future[Option[NutrientMap]] =
      db.run(companion.referenceNutrientMap(userId))

    override def createReferenceNutrient(
        userId: UserId,
        referenceNutrientCreation: ReferenceNutrientCreation
    ): Future[ServerError.Or[ReferenceNutrient]] =
      db.run(companion.createReferenceNutrient(userId, referenceNutrientCreation))
        .map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.ReferenceNutrient.Creation(error.getMessage).asServerError)
        }

    override def updateReferenceNutrient(
        userId: UserId,
        referenceNutrientUpdate: ReferenceNutrientUpdate
    ): Future[ServerError.Or[ReferenceNutrient]] =
      db.run(companion.updateReferenceNutrient(userId, referenceNutrientUpdate))
        .map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.ReferenceNutrient.Update(error.getMessage).asServerError)
        }

    override def deleteReferenceNutrient(
        userId: UserId,
        nutrientCode: NutrientCode
    ): Future[Boolean] =
      db.run(companion.deleteReferenceNutrient(userId, nutrientCode))

  }

  trait Companion {
    def nutrientsOverTime(userId: UserId, requestInterval: RequestInterval)(implicit ec: ExecutionContext): DBIO[Stats]
    def referenceNutrientMap(userId: UserId)(implicit ec: ExecutionContext): DBIO[Option[NutrientMap]]

    def createReferenceNutrient(
        userId: UserId,
        referenceNutrientCreation: ReferenceNutrientCreation
    )(implicit ec: ExecutionContext): DBIO[ReferenceNutrient]

    def updateReferenceNutrient(
        userId: UserId,
        referenceNutrientUpdate: ReferenceNutrientUpdate
    )(implicit ec: ExecutionContext): DBIO[ReferenceNutrient]

    def deleteReferenceNutrient(
        userId: UserId,
        nutrientCode: NutrientCode
    )(implicit ec: ExecutionContext): DBIO[Boolean]

  }

  object Live extends Companion {

    private case class RecipeNutrientMap(
        recipe: Recipe,
        nutrientMap: NutrientMap
    )

    override def nutrientsOverTime(
        userId: UserId,
        requestInterval: RequestInterval
    )(implicit
        ec: ExecutionContext
    ): DBIO[Stats] = {
      val dateFilter = DBIOUtil.dateFilter(requestInterval.from, requestInterval.to)
      for {
        mealIdsPlain <- Tables.Meal.filter(m => dateFilter(m.consumedOnDate)).map(_.id).result
        mealIds = mealIdsPlain.map(_.transformInto[MealId])
        meals <- mealIds.traverse(MealService.Live.getMeal(userId, _)).map(_.flatten)
        mealEntries <-
          mealIds
            .traverse(mealId =>
              MealService.Live
                .getMealEntries(userId, mealId)
                .map(mealId -> _): DBIO[(MealId, Seq[MealEntry])]
            )
            .map(_.toMap)
        nutrientsPerRecipe <-
          mealIds
            .flatMap(mealEntries(_).map(_.recipeId))
            .distinct
            .traverse { recipeId =>
              val transformer = for {
                recipe      <- OptionT(RecipeService.Live.getRecipe(userId, recipeId))
                ingredients <- OptionT.liftF(RecipeService.Live.getIngredients(userId, recipeId))
                nutrients   <- OptionT.liftF(NutrientService.Live.nutrientsOfIngredients(ingredients))
              } yield recipeId -> RecipeNutrientMap(
                recipe = recipe,
                nutrientMap = nutrients
              )
              transformer.value
            }
            .map(_.flatten.toMap)
        allNutrients <- NutrientService.Live.all
        referenceMap <- referenceNutrientMap(userId)
      } yield {
        val nutrientMap = meals
          .flatMap(m => mealEntries(m.id))
          .map { me =>
            val recipeNutrientMap = nutrientsPerRecipe(me.recipeId)
            (me.numberOfServings / recipeNutrientMap.recipe.numberOfServings) *: recipeNutrientMap.nutrientMap
          }
          .qsum
        Stats(
          meals = meals,
          nutrientMap = MapUtil.unionWith(nutrientMap, allNutrients.map(n => n -> BigDecimal(0)).toMap)((x, _) => x),
          referenceNutrientMap = referenceMap.getOrElse(Map.empty)
        )
      }
    }

    override def referenceNutrientMap(userId: UserId)(implicit ec: ExecutionContext): DBIO[Option[NutrientMap]] = {
      val transformer = for {
        referenceNutrients <- OptionT.liftF(referenceNutrientsByUserId(userId))
        referenceNutrientAmounts <- referenceNutrients.traverse { referenceNutrient =>
          OptionT(nutrientNameByCode(referenceNutrient.nutrientCode)).map(nutrientNameRow =>
            nutrientNameRow.transformInto[Nutrient] -> referenceNutrient.amount
          )
        }
      } yield referenceNutrientAmounts.toMap

      transformer.value
    }

    override def createReferenceNutrient(userId: UserId, referenceNutrientCreation: ReferenceNutrientCreation)(implicit
        ec: ExecutionContext
    ): DBIO[ReferenceNutrient] = {
      val referenceNutrient    = ReferenceNutrientCreation.create(referenceNutrientCreation)
      val referenceNutrientRow = (referenceNutrient, userId).transformInto[Tables.ReferenceNutrientRow]
      val query                = referenceNutrientQuery(userId, referenceNutrientCreation.nutrientCode)
      for {
        exists <- query.exists.result
        row <-
          if (exists)
            query
              .update(referenceNutrientRow)
              .andThen(query.result.head)
          else
            Tables.ReferenceNutrient.returning(Tables.ReferenceNutrient) += referenceNutrientRow
      } yield row.transformInto[ReferenceNutrient]
    }

    override def updateReferenceNutrient(userId: UserId, referenceNutrientUpdate: ReferenceNutrientUpdate)(implicit
        ec: ExecutionContext
    ): DBIO[ReferenceNutrient] = {
      val findAction =
        OptionT(
          referenceNutrientQuery(
            userId,
            referenceNutrientUpdate.nutrientCode
          ).result.headOption: DBIO[Option[Tables.ReferenceNutrientRow]]
        ).map(_.transformInto[ReferenceNutrient])
          .getOrElseF(DBIO.failed(DBError.ReferenceNutrientNotFound))
      for {
        referenceNutrientRow <- findAction
        _ <- referenceNutrientQuery(userId, referenceNutrientUpdate.nutrientCode).update(
          (
            ReferenceNutrientUpdate
              .update(referenceNutrientRow, referenceNutrientUpdate),
            userId
          )
            .transformInto[Tables.ReferenceNutrientRow]
        )
        updatedReferenceNutrient <- findAction
      } yield updatedReferenceNutrient
    }

    override def deleteReferenceNutrient(userId: UserId, nutrientCode: NutrientCode)(implicit
        ec: ExecutionContext
    ): DBIO[Boolean] =
      referenceNutrientQuery(userId, nutrientCode).delete
        .map(_ > 0)

    private def referenceNutrientsByUserId(userId: UserId): DBIO[Seq[Tables.ReferenceNutrientRow]] =
      Tables.ReferenceNutrient
        .filter(_.userId === userId.transformInto[UUID])
        .result

    private def nutrientNameByCode(nutrientCode: Int): DBIO[Option[Tables.NutrientNameRow]] =
      Tables.NutrientName
        .filter(_.nutrientCode === nutrientCode)
        .result
        .headOption

    private def referenceNutrientQuery(userId: UserId, nutrientCode: NutrientCode) =
      Tables.ReferenceNutrient.filter(referenceNutrient =>
        referenceNutrient.userId === userId.transformInto[UUID] &&
          referenceNutrient.nutrientCode === nutrientCode.transformInto[Int]
      )

  }

}
