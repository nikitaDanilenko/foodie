package controllers.stats

import action.UserAction
import controllers.reference.ReferenceEntry
import io.circe.syntax._
import io.scalaland.chimney.dsl.TransformerOps
import play.api.libs.circe.Circe
import play.api.mvc._
import services.ReferenceMapId
import services.nutrient.NutrientService
import services.reference.ReferenceService
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
    nutrientService: NutrientService,
    referenceService: ReferenceService
)(implicit ec: ExecutionContext)
    extends AbstractController(controllerComponents)
    with Circe {

  def get(from: Option[String], to: Option[String]): Action[AnyContent] =
    userAction.async { request =>
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

  def referenceNutrients(referenceMapId: UUID): Action[AnyContent] =
    userAction.async { request =>
      referenceService
        .getReferenceNutrientsMap(request.user.id, referenceMapId.transformInto[ReferenceMapId])
        .map { nutrientMap =>
          nutrientMap
            .map {
              _.map {
                case (nutrient, amount) =>
                  ReferenceEntry(
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
    userAction.async {
      nutrientService.all.map(
        _.map(_.transformInto[Nutrient])
          .pipe(_.asJson)
          .pipe(Ok(_))
      )
    }

}
