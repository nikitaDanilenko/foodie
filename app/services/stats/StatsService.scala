package services.stats

import cats.syntax.traverse._
import db.generated.Tables
import io.scalaland.chimney.dsl.TransformerOps
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.{ MealId, RecipeId, UserId }
import services.meal.MealService
import services.nutrient.{ NutrientMap, NutrientService }
import services.recipe.{ Ingredient, RecipeService }
import slick.dbio.DBIO
import javax.inject.Inject

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
        nutrientsPerRecipe <-
          meals
            .flatMap(_.entries.map(_.recipeId))
            .distinct
            .traverse(recipeId =>
              RecipeService.Live
                .getIngredients(userId, recipeId)
                .flatMap(NutrientService.Live.nutrientsOfIngredients)
                .map(recipeId -> _): DBIO[(RecipeId, NutrientMap)]
            )
            .map(_.toMap)
      } yield {
        val nutrientMap = meals
          .flatMap(_.entries)
          .map(me => me.factor *: nutrientsPerRecipe(me.recipeId))
          .qsum
        Stats(
          meals = meals,
          nutrientMap = nutrientMap
        )
      }
    }

  }

}
