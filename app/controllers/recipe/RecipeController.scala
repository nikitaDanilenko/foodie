package controllers.recipe

import action.UserAction
import cats.data.{ EitherT, OptionT }
import db.{ FoodId, IngredientId, RecipeId }
import errors.ErrorContext
import io.circe.syntax._
import io.scalaland.chimney.dsl.TransformerOps
import play.api.libs.circe.Circe
import play.api.mvc._
import services.DBError
import services.complex.ingredient.ComplexIngredientService
import services.recipe.RecipeService
import services.rescale.RescaleService
import utils.TransformerUtils.Implicits._
import utils.date.SimpleDate

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.ExecutionContext
import scala.util.chaining._

class RecipeController @Inject() (
    controllerComponents: ControllerComponents,
    recipeService: RecipeService,
    recipeDuplication: services.duplication.recipe.Duplication,
    rescaleService: RescaleService,
    complexIngredientService: ComplexIngredientService,
    userAction: UserAction
)(implicit ec: ExecutionContext)
    extends AbstractController(controllerComponents)
    with Circe {

  def getMeasures: Action[AnyContent] =
    userAction.async {
      recipeService.allMeasures
        .map(
          _.map(_.transformInto[Measure])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def getFoods: Action[AnyContent] =
    userAction.async {
      recipeService.allFoods
        .map(
          _.map(_.transformInto[Food])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def getFood(foodId: Int): Action[AnyContent] =
    userAction.async {
      OptionT(
        recipeService
          .getFoodInfo(foodId.transformInto[FoodId])
      ).fold(
        NotFound(ErrorContext.Recipe.General("Food not found").asServerError.asJson): Result
      )(
        _.pipe(_.transformInto[FoodInfo])
          .pipe(_.asJson)
          .pipe(Ok(_))
      ).recover(errorHandler)
    }

  def getRecipes: Action[AnyContent] =
    userAction.async { request =>
      recipeService
        .allRecipes(request.user.id)
        .map(
          _.map(_.transformInto[Recipe])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def get(id: UUID): Action[AnyContent] =
    userAction.async { request =>
      OptionT(recipeService.getRecipe(request.user.id, id.transformInto[RecipeId]))
        .fold(
          NotFound(ErrorContext.Recipe.NotFound.asServerError.asJson): Result
        )(
          _.pipe(_.transformInto[Recipe])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def create: Action[RecipeCreation] =
    userAction.async(circe.tolerantJson[RecipeCreation]) { request =>
      EitherT(
        recipeService
          .createRecipe(request.user.id, request.body.transformInto[services.recipe.RecipeCreation])
      )
        .map(
          _.pipe(_.transformInto[Recipe])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .fold(controllers.badRequest, identity)
        .recover(errorHandler)
    }

  def update(id: UUID): Action[RecipeUpdate] =
    userAction.async(circe.tolerantJson[RecipeUpdate]) { request =>
      EitherT(
        recipeService
          .updateRecipe(
            request.user.id,
            id.transformInto[RecipeId],
            request.body.transformInto[services.recipe.RecipeUpdate]
          )
      )
        .map(
          _.pipe(_.transformInto[Recipe])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .fold(controllers.badRequest, identity)
        .recover(errorHandler)
    }

  def delete(id: UUID): Action[AnyContent] =
    userAction.async { request =>
      recipeService
        .deleteRecipe(request.user.id, id.transformInto[RecipeId])
        .map(
          _.pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def getIngredients(id: UUID): Action[AnyContent] =
    userAction.async { request =>
      recipeService
        .getIngredients(
          request.user.id,
          id.transformInto[RecipeId]
        )
        .map(
          _.pipe(_.map(_.transformInto[Ingredient]).asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def duplicate(id: UUID): Action[SimpleDate] =
    userAction.async(circe.tolerantJson[SimpleDate]) { request =>
      EitherT(
        recipeDuplication
          .duplicate(
            userId = request.user.id,
            id = id.transformInto[RecipeId],
            timeOfDuplication = request.body
          )
      )
        .map(
          _.pipe(_.transformInto[Recipe])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .fold(controllers.badRequest, identity)
        .recover(errorHandler)
    }

  def rescale(id: UUID): Action[AnyContent] =
    userAction.async { request =>
      EitherT(
        rescaleService
          .rescale(
            request.user.id,
            id.transformInto[RecipeId]
          )
      )
        .map(
          _.pipe(_.transformInto[Recipe])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .fold(controllers.badRequest, identity)
        .recover(errorHandler)
    }

  def addIngredient(recipeId: UUID): Action[IngredientCreation] =
    userAction.async(circe.tolerantJson[IngredientCreation]) { request =>
      EitherT(
        recipeService.addIngredient(
          userId = request.user.id,
          recipeId = recipeId.transformInto[RecipeId],
          ingredientCreation = request.body.transformInto[services.recipe.IngredientCreation]
        )
      )
        .fold(
          controllers.badRequest,
          _.pipe(_.transformInto[Ingredient])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def removeIngredient(recipeId: UUID, id: UUID): Action[AnyContent] =
    userAction.async { request =>
      recipeService
        .removeIngredient(request.user.id, recipeId.transformInto[RecipeId], id.transformInto[IngredientId])
        .map(
          _.pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def updateIngredient(recipeId: UUID, id: UUID): Action[IngredientUpdate] =
    userAction.async(circe.tolerantJson[IngredientUpdate]) { request =>
      EitherT(
        recipeService.updateIngredient(
          userId = request.user.id,
          recipeId = recipeId.transformInto[RecipeId],
          ingredientId = id.transformInto[IngredientId],
          ingredientUpdate = request.body.transformInto[services.recipe.IngredientUpdate]
        )
      )
        .fold(
          controllers.badRequest,
          _.pipe(_.transformInto[Ingredient])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def getComplexIngredients(id: UUID): Action[AnyContent] =
    userAction.async { request =>
      complexIngredientService
        .all(
          request.user.id,
          id.transformInto[RecipeId]
        )
        .map(
          _.pipe(_.map(_.transformInto[ComplexIngredient]).asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def addComplexIngredient(recipeId: UUID): Action[ComplexIngredient] =
    userAction.async(circe.tolerantJson[ComplexIngredient]) { request =>
      EitherT(
        complexIngredientService.create(
          userId = request.user.id,
          // TODO
          complexIngredient = (request.body, recipeId).transformInto[services.complex.ingredient.ComplexIngredient]
        )
      )
        .fold(
          controllers.badRequest,
          _.pipe(_.transformInto[ComplexIngredient])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def removeComplexIngredient(recipeId: UUID, id: UUID): Action[AnyContent] =
    userAction.async { request =>
      complexIngredientService
        .delete(request.user.id, recipeId.transformInto[RecipeId], id.transformInto[RecipeId])
        .map(
          _.pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def updateComplexIngredient(recipeId: UUID): Action[ComplexIngredient] =
    userAction.async(circe.tolerantJson[ComplexIngredient]) { request =>
      EitherT(
        complexIngredientService.update(
          userId = request.user.id,
          // TODO
          complexIngredient = (request.body, recipeId).transformInto[services.complex.ingredient.ComplexIngredient]
        )
      )
        .fold(
          controllers.badRequest,
          _.pipe(_.transformInto[ComplexIngredient])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  private def errorHandler: PartialFunction[Throwable, Result] = { case error =>
    val context = error match {
      case DBError.Recipe.NotFound =>
        ErrorContext.Recipe.NotFound
      case DBError.Recipe.IngredientNotFound =>
        ErrorContext.Recipe.Ingredient.NotFound
      case DBError.Complex.Ingredient.NotFound =>
        ErrorContext.Recipe.ComplexIngredient.NotFound
      case _ =>
        ErrorContext.Recipe.General(error.getMessage)
    }

    BadRequest(context.asServerError.asJson)
  }

}
