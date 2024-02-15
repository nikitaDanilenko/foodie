package controllers.stats

import action.UserAction
import cats.data.OptionT
import controllers.common.RequestInterval
import db.ProfileId
import errors.ErrorContext
import io.circe.syntax._
import io.scalaland.chimney.dsl.TransformerOps
import play.api.libs.circe.Circe
import play.api.mvc._
import services.common
import services.complex.food.ComplexFoodService
import services.nutrient.NutrientService
import services.stats.StatsService
import utils.TransformerUtils.Implicits._
import utils.date.Date

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.ExecutionContext
import scala.util.chaining.scalaUtilChainingOps

class StatsController @Inject() (
    controllerComponents: ControllerComponents,
    userAction: UserAction,
    statsService: StatsService,
    complexFoodService: ComplexFoodService,
    nutrientService: NutrientService
)(implicit ec: ExecutionContext)
    extends AbstractController(controllerComponents)
    with Circe {

  def get(profileId: UUID, from: Option[String], to: Option[String]): Action[AnyContent] =
    userAction.async { request =>
      val typedProfileId = profileId.transformInto[ProfileId]
      val transformer = for {
        stats <-
          OptionT.liftF(
            statsService
              .nutrientsOverTime(
                userId = request.user.id,
                profileId = typedProfileId,
                requestInterval = RequestInterval(
                  from = from.flatMap(Date.parse),
                  to = to.flatMap(Date.parse)
                ).transformInto[common.RequestInterval]
              )
          )
        weightInGrams <- OptionT(statsService.weightOfMeals(request.user.id, typedProfileId, stats.meals.map(_.id)))
      } yield (stats, weightInGrams)
        .pipe(_.transformInto[Stats])
        .pipe(_.asJson)
        .pipe(Ok(_))

      transformer
        .getOrElse(NotFound(ErrorContext.Stats.General("Error fetching stats over time.").asServerError.asJson))
        .recover(errorHandler)
    }

  def ofFood(foodId: Int): Action[AnyContent] =
    userAction.async {
      statsService
        .nutrientsOfFood(foodId.transformInto[db.FoodId])
        .map(
          _.fold(NotFound(ErrorContext.Stats.General("Nutrient not found").asServerError.asJson): Result)(
            _.pipe(nutrients => (nutrients, BigDecimal(100)).transformInto[FoodStats])
              .pipe(_.asJson)
              .pipe(Ok(_))
          )
        )
        .recover(errorHandler)
    }

  def ofComplexFood(recipeId: UUID): Action[AnyContent] =
    userAction.async { request =>
      val typedRecipeId = recipeId.transformInto[db.ComplexFoodId]
      val transformer = for {
        nutrients   <- OptionT(statsService.nutrientsOfComplexFood(request.user.id, typedRecipeId))
        complexFood <- OptionT(complexFoodService.get(request.user.id, typedRecipeId))
      } yield (nutrients, complexFood.amountGrams)
        .pipe(_.transformInto[TotalOnlyStats])
        .pipe(_.asJson)
        .pipe(Ok(_))

      transformer
        .getOrElse(
          NotFound(ErrorContext.Stats.General("Error fetching stats for complex food.").asServerError.asJson)
        )
        .recover(errorHandler)
    }

  def ofRecipe(recipeId: UUID): Action[AnyContent] =
    userAction.async { request =>
      val typedRecipeId = recipeId.transformInto[db.RecipeId]
      val transformer = for {
        nutrients     <- OptionT(statsService.nutrientsOfRecipe(request.user.id, typedRecipeId))
        weightInGrams <- OptionT(statsService.weightOfRecipe(request.user.id, typedRecipeId))
      } yield (nutrients, weightInGrams)
        .pipe(_.transformInto[TotalOnlyStats])
        .pipe(_.asJson)
        .pipe(Ok(_))

      transformer
        .getOrElse(
          NotFound(ErrorContext.Stats.General("Error fetching stats for recipe.").asServerError.asJson)
        )
        .recover(errorHandler)
    }

  def ofMeal(profileId: UUID, mealId: UUID): Action[AnyContent] =
    userAction.async { request =>
      val typedProfileId = profileId.transformInto[db.ProfileId]
      val typedMealId    = mealId.transformInto[db.MealId]

      val transformer = for {
        nutrients     <- OptionT.liftF(statsService.nutrientsOfMeal(request.user.id, typedProfileId, typedMealId))
        weightInGrams <- OptionT(statsService.weightOfMeal(request.user.id, typedProfileId, typedMealId))
      } yield (nutrients, weightInGrams)
        .pipe(_.transformInto[TotalOnlyStats])
        .pipe(_.asJson)
        .pipe(Ok(_))

      transformer
        .getOrElse(
          NotFound(ErrorContext.Stats.General(s"Error while fetching stats for meal.").asServerError.asJson)
        )
        .recover(errorHandler)
    }

  def allNutrients: Action[AnyContent] =
    userAction.async {
      nutrientService.all
        .map(
          _.map(_.transformInto[Nutrient])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def recipeOccurrences(profileId: UUID): Action[AnyContent] = userAction.async { request =>
    statsService
      .recipeOccurrences(request.user.id, profileId.transformInto[ProfileId])
      .map(
        _.map(_.transformInto[RecipeOccurrence])
          .pipe(_.asJson)
          .pipe(Ok(_))
      )
      .recover(errorHandler)
  }

  private def errorHandler: PartialFunction[Throwable, Result] = { case error =>
    val context = ErrorContext.Recipe.General(error.getMessage)

    BadRequest(context.asServerError.asJson)
  }

}
