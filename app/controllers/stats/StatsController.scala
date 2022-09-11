package controllers.stats

import action.JwtAction
import io.circe.syntax._
import io.scalaland.chimney.dsl.TransformerOps
import javax.inject.Inject
import play.api.libs.circe.Circe
import play.api.mvc.{ AbstractController, Action, AnyContent, ControllerComponents }
import services.stats.StatsService
import utils.date.Date

import scala.concurrent.ExecutionContext
import scala.util.chaining.scalaUtilChainingOps

class StatsController @Inject() (
    controllerComponents: ControllerComponents,
    jwtAction: JwtAction,
    statsService: StatsService
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

}
