package controllers.complex

import action.UserAction
import cats.data.EitherT
import db.ComplexFoodId
import errors.ErrorContext
import errors.ErrorContext._
import io.circe.syntax._
import io.scalaland.chimney.dsl._
import play.api.libs.circe.Circe
import play.api.mvc._
import services.DBError
import services.complex.food.ComplexFoodService
import utils.TransformerUtils.Implicits._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.ExecutionContext
import scala.util.chaining._

class ComplexFoodController @Inject() (
    controllerComponents: ControllerComponents,
    userAction: UserAction,
    complexFoodService: ComplexFoodService
)(implicit ec: ExecutionContext)
    extends AbstractController(controllerComponents)
    with Circe {

  def all: Action[AnyContent] =
    userAction.async { request =>
      complexFoodService
        .all(request.user.id)
        .map(
          _.map(_.transformInto[ComplexFood])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def get(complexFoodId: UUID): Action[AnyContent] =
    userAction.async { request =>
      complexFoodService
        .get(request.user.id, complexFoodId.transformInto[ComplexFoodId])
        .map(
          _.fold(NotFound(ErrorContext.ComplexFood.NotFound.asServerError.asJson): Result)(
            _.transformInto[ComplexFood]
              .pipe(_.asJson)
              .pipe(Ok(_))
          )
        )
        .recover(errorHandler)
    }

  def create: Action[ComplexFoodIncoming] =
    userAction.async(circe.tolerantJson[ComplexFoodIncoming]) { request =>
      EitherT(
        complexFoodService
          .create(request.user.id, request.body.transformInto[services.complex.food.ComplexFoodIncoming])
      )
        .fold(
          controllers.badRequest,
          _.pipe(_.transformInto[ComplexFood])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def update(complexFoodId: UUID): Action[ComplexFoodUpdate] =
    userAction.async(circe.tolerantJson[ComplexFoodUpdate]) { request =>
      EitherT(
        complexFoodService
          .update(
            request.user.id,
            complexFoodId.transformInto[ComplexFoodId],
            request.body.transformInto[services.complex.food.ComplexFoodUpdate]
          )
      )
        .fold(
          controllers.badRequest,
          _.pipe(_.transformInto[ComplexFood])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def delete(complexFoodId: UUID): Action[AnyContent] =
    userAction.async { request =>
      complexFoodService
        .delete(request.user.id, complexFoodId.transformInto[ComplexFoodId])
        .map(
          _.pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  private def errorHandler: PartialFunction[Throwable, Result] = { case error =>
    val context = error match {
      case DBError.Complex.Food.NotFound =>
        ErrorContext.ComplexFood.NotFound
      case DBError.Complex.Food.RecipeNotFound =>
        ErrorContext.ComplexFood.Reference
      case _ =>
        ErrorContext.ComplexFood.General(error.getMessage)
    }

    BadRequest(context.asServerError.asJson)
  }

}
