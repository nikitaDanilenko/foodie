package controllers.stats

import action.JwtAction
import cats.data.EitherT
import errors.{ ErrorContext, ServerError }
import io.circe.syntax._
import io.scalaland.chimney.dsl.TransformerOps
import javax.inject.Inject
import play.api.libs.circe.Circe
import play.api.mvc._
import services.NutrientCode
import services.nutrient.NutrientService
import services.stats.{ DBError, StatsService }
import utils.date.Date
import utils.TransformerUtils.Implicits._

import scala.concurrent.ExecutionContext
import scala.util.chaining.scalaUtilChainingOps

class StatsController @Inject() (
    controllerComponents: ControllerComponents,
    jwtAction: JwtAction,
    statsService: StatsService,
    nutrientService: NutrientService
)(implicit ec: ExecutionContext)
    extends AbstractController(controllerComponents)
    with Circe {

  def get(from: Option[String], to: Option[String]): Action[AnyContent] =
    jwtAction.async { request =>
      statsService
        .nutrientsOverTime(
          userId = request.user.id,
          requestInterval = RequestInterval(
            from = from.flatMap(Date.parse),
            to = to.flatMap(Date.parse)
          ).transformInto[services.stats.RequestInterval]
        )
        .map(
          _.pipe(_.transformInto[Stats])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  def referenceNutrients: Action[AnyContent] =
    jwtAction.async { request =>
      statsService
        .referenceNutrientMap(request.user.id)
        .map { nutrientMap =>
          nutrientMap
            .map {
              _.map {
                case (nutrient, amount) =>
                  ReferenceNutrient(
                    nutrientCode = nutrient.code,
                    amount = amount
                  )
              }
            }
            .getOrElse(List.empty)
            .pipe(_.asJson)
            .pipe(Ok(_))
        }
        .recover {
          case error =>
            BadRequest(error.getMessage)
        }
    }

  def allNutrients: Action[AnyContent] =
    jwtAction.async {
      nutrientService.all.map(
        _.map(_.transformInto[Nutrient])
          .pipe(_.asJson)
          .pipe(Ok(_))
      )
    }

  def createReferenceNutrient: Action[ReferenceNutrientCreation] =
    jwtAction.async(circe.tolerantJson[ReferenceNutrientCreation]) { request =>
      EitherT(
        statsService
          .createReferenceNutrient(
            request.user.id,
            request.body.transformInto[services.stats.ReferenceNutrientCreation]
          )
      )
        .map(
          _.pipe(_.transformInto[ReferenceNutrient])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .leftMap(badRequest)
        .merge
        .recover(referenceNutrientErrorHandler)
    }

  def updateReferenceNutrient: Action[ReferenceNutrientUpdate] =
    jwtAction.async(circe.tolerantJson[ReferenceNutrientUpdate]) { request =>
      EitherT(
        statsService
          .updateReferenceNutrient(request.user.id, request.body.transformInto[services.stats.ReferenceNutrientUpdate])
      )
        .map(
          _.pipe(_.transformInto[ReferenceNutrient])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .leftMap(badRequest)
        .merge
        .recover(referenceNutrientErrorHandler)
    }

  def deleteReferenceNutrient(nutrientCode: Int): Action[AnyContent] =
    jwtAction.async { request =>
      statsService
        .deleteReferenceNutrient(request.user.id, nutrientCode.transformInto[NutrientCode])
        .map(
          _.pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  private def badRequest(serverError: ServerError): Result =
    BadRequest(serverError.asJson)

  // TODO: Consider handling errors on service level
  private def referenceNutrientErrorHandler: PartialFunction[Throwable, Result] = {
    case error =>
      val context = error match {
        case DBError.ReferenceNutrientNotFound =>
          ErrorContext.ReferenceNutrient.NotFound
        case _ =>
          ErrorContext.ReferenceNutrient.General(error.getMessage)
      }

      BadRequest(context.asServerError.asJson)
  }

}
