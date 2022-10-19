package controllers.reference

import action.UserAction
import cats.data.{ EitherT, OptionT }
import errors.{ ErrorContext, ServerError }
import io.circe.syntax._
import io.scalaland.chimney.dsl.TransformerOps
import play.api.libs.circe.Circe
import play.api.mvc._
import services.{ NutrientCode, ReferenceMapId }
import services.reference.{ DBError, ReferenceService }
import utils.TransformerUtils.Implicits._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.ExecutionContext
import scala.util.chaining._

class ReferenceController @Inject() (
    controllerComponents: ControllerComponents,
    referenceService: ReferenceService,
    userAction: UserAction
)(implicit ec: ExecutionContext)
    extends AbstractController(controllerComponents)
    with Circe {

  def all: Action[AnyContent] =
    userAction.async { request =>
      referenceService
        .allReferenceMaps(
          userId = request.user.id
        )
        .map(
          _.pipe(
            _.map(_.transformInto[ReferenceMap])
          )
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  def allTrees: Action[AnyContent] =
    userAction.async { request =>
      referenceService
        .allReferenceTrees(
          userId = request.user.id
        )
        .map(
          _.pipe(
            _.map(_.transformInto[ReferenceTree])
          )
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  def get(id: UUID): Action[AnyContent] =
    userAction.async { request =>
      OptionT(referenceService.getReferenceMap(request.user.id, id.transformInto[ReferenceMapId])).fold(
        NotFound: Result
      )(
        _.pipe(_.transformInto[ReferenceMap])
          .pipe(_.asJson)
          .pipe(Ok(_))
      )
    }

  def create: Action[ReferenceMapCreation] =
    userAction.async(circe.tolerantJson[ReferenceMapCreation]) { request =>
      EitherT(
        referenceService
          .createReferenceMap(request.user.id, request.body.transformInto[services.reference.ReferenceMapCreation])
      )
        .map(
          _.pipe(_.transformInto[ReferenceMap])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .fold(badRequest, identity)
        .recover(referenceMapErrorHandler)
    }

  def update: Action[ReferenceMapUpdate] =
    userAction.async(circe.tolerantJson[ReferenceMapUpdate]) { request =>
      EitherT(
        referenceService
          .updateReferenceMap(request.user.id, request.body.transformInto[services.reference.ReferenceMapUpdate])
      )
        .map(
          _.pipe(_.transformInto[ReferenceMap])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .fold(badRequest, identity)
        .recover(referenceMapErrorHandler)
    }

  def delete(id: UUID): Action[AnyContent] =
    userAction.async { request =>
      referenceService
        .delete(request.user.id, id.transformInto[ReferenceMapId])
        .map(
          _.pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  def allReferenceEntries(id: UUID): Action[AnyContent] =
    userAction.async { request =>
      referenceService
        .allReferenceEntries(
          request.user.id,
          id.transformInto[ReferenceMapId]
        )
        .map(
          _.pipe(_.map(_.transformInto[ReferenceEntry]).asJson)
            .pipe(Ok(_))
        )
        .recover(referenceMapErrorHandler)
    }

  def addReferenceEntry: Action[ReferenceEntryCreation] =
    userAction.async(circe.tolerantJson[ReferenceEntryCreation]) { request =>
      EitherT(
        referenceService.addReferenceEntry(
          userId = request.user.id,
          referenceEntryCreation = request.body.transformInto[services.reference.ReferenceEntryCreation]
        )
      )
        .fold(
          badRequest,
          _.pipe(_.transformInto[ReferenceEntry])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(referenceMapErrorHandler)
    }

  def updateReferenceEntry: Action[ReferenceEntryUpdate] =
    userAction.async(circe.tolerantJson[ReferenceEntryUpdate]) { request =>
      EitherT(
        referenceService.updateReferenceEntry(
          userId = request.user.id,
          referenceEntryUpdate = request.body.transformInto[services.reference.ReferenceEntryUpdate]
        )
      )
        .fold(
          badRequest,
          _.pipe(_.transformInto[ReferenceEntry])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(referenceMapErrorHandler)
    }

  def deleteReferenceEntry(mapId: UUID, nutrientCode: Int): Action[AnyContent] =
    userAction.async { request =>
      referenceService
        .deleteReferenceEntry(
          request.user.id,
          mapId.transformInto[ReferenceMapId],
          nutrientCode.transformInto[NutrientCode]
        )
        .map(
          _.pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  private def badRequest(serverError: ServerError): Result =
    BadRequest(serverError.asJson)

  private def referenceMapErrorHandler: PartialFunction[Throwable, Result] = {
    case error =>
      val context = error match {
        case DBError.ReferenceMapNotFound =>
          ErrorContext.ReferenceMap.NotFound
        case DBError.ReferenceEntryNotFound =>
          ErrorContext.ReferenceMap.Entry.NotFound
        case _ =>
          ErrorContext.ReferenceMap.General(error.getMessage)
      }

      BadRequest(context.asServerError.asJson)
  }

}
