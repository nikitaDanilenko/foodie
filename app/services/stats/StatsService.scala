package services.stats

import cats.data.OptionT
import cats.syntax.traverse._
import db.generated.Tables
import io.scalaland.chimney.dsl.TransformerOps
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.{ MealId, RecipeId, UserId }
import services.meal.{ MealEntry, MealService }
import services.nutrient.{ NutrientMap, NutrientService }
import services.recipe.{ Ingredient, Recipe, RecipeService }
import slick.dbio.DBIO
import javax.inject.Inject
import utils.DBIOUtil.instances._
import cats.syntax.contravariantSemigroupal._

import scala.concurrent.{ ExecutionContext, Future }
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil
import utils.DBIOUtil.instances._
import spire.implicits._
import utils.TransformerUtils.Implicits._

trait StatsService {

  def nutrientsOverTime(userId: UserId, requestInterval: RequestInterval): Future[Stats]

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

  }

  trait Companion {
    def nutrientsOverTime(userId: UserId, requestInterval: RequestInterval)(implicit ec: ExecutionContext): DBIO[Stats]
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
          nutrientMap = nutrientMap
        )
      }
    }

  }

}
