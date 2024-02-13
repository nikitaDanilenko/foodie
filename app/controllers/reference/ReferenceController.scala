package controllers.reference

import action.UserAction
import cats.data.{ EitherT, OptionT }
import db.{ NutrientCode, ReferenceMapId }
import errors.{ ErrorContext, ServerError }
import io.circe.syntax._
import io.scalaland.chimney.dsl.TransformerOps
import play.api.libs.circe.Circe
import play.api.mvc._
import services.DBError
import services.reference.ReferenceService
import utils.TransformerUtils.Implicits._
import utils.date.SimpleDate

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.ExecutionContext
import scala.util.chaining._

class ReferenceController @Inject() (
    controllerComponents: ControllerComponents,
    referenceService: ReferenceService,
    referenceDuplication: services.duplication.reference.Duplication,
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
        .recover(errorHandler)
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
        .recover(errorHandler)
    }

  def get(referenceMapId: UUID): Action[AnyContent] =
    userAction.async { request =>
      OptionT(referenceService.getReferenceMap(request.user.id, referenceMapId.transformInto[ReferenceMapId]))
        .fold(
          NotFound(ErrorContext.ReferenceMap.NotFound.asServerError.asJson): Result
        )(
          _.pipe(_.transformInto[ReferenceMap])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
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
        .recover(errorHandler)
    }

  def update(referenceMapId: UUID): Action[ReferenceMapUpdate] =
    userAction.async(circe.tolerantJson[ReferenceMapUpdate]) { request =>
      EitherT(
        referenceService
          .updateReferenceMap(
            request.user.id,
            referenceMapId.transformInto[ReferenceMapId],
            request.body.transformInto[services.reference.ReferenceMapUpdate]
          )
      )
        .map(
          _.pipe(_.transformInto[ReferenceMap])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .fold(badRequest, identity)
        .recover(errorHandler)
    }

  def delete(referenceMapId: UUID): Action[AnyContent] =
    userAction.async { request =>
      referenceService
        .delete(request.user.id, referenceMapId.transformInto[ReferenceMapId])
        .map(
          _.pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def allReferenceEntries(referenceMapId: UUID): Action[AnyContent] =
    userAction.async { request =>
      referenceService
        .allReferenceEntries(
          request.user.id,
          referenceMapId.transformInto[ReferenceMapId]
        )
        .map(
          _.pipe(_.map(_.transformInto[ReferenceEntry]).asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def duplicate(referenceMapId: UUID): Action[SimpleDate] =
    userAction.async(circe.tolerantJson[SimpleDate]) { request =>
      EitherT(
        referenceDuplication
          .duplicate(
            userId = request.user.id,
            id = referenceMapId.transformInto[ReferenceMapId],
            timeOfDuplication = request.body
          )
      )
        .map(
          _.pipe(_.transformInto[ReferenceMap])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .fold(controllers.badRequest, identity)
        .recover(errorHandler)
    }

  def addReferenceEntry(referenceMapId: UUID): Action[ReferenceEntryCreation] =
    userAction.async(circe.tolerantJson[ReferenceEntryCreation]) { request =>
      EitherT(
        referenceService.addReferenceEntry(
          userId = request.user.id,
          referenceMapId = referenceMapId.transformInto[ReferenceMapId],
          referenceEntryCreation = request.body.transformInto[services.reference.ReferenceEntryCreation]
        )
      )
        .fold(
          badRequest,
          _.pipe(_.transformInto[ReferenceEntry])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def updateReferenceEntry(referenceMapId: UUID, nutrientCode: Int): Action[ReferenceEntryUpdate] =
    userAction.async(circe.tolerantJson[ReferenceEntryUpdate]) { request =>
      EitherT(
        referenceService.updateReferenceEntry(
          userId = request.user.id,
          referenceMapId = referenceMapId.transformInto[ReferenceMapId],
          nutrientCode = nutrientCode.transformInto[NutrientCode],
          referenceEntryUpdate = request.body.transformInto[services.reference.ReferenceEntryUpdate]
        )
      )
        .fold(
          badRequest,
          _.pipe(_.transformInto[ReferenceEntry])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def deleteReferenceEntry(referenceMapId: UUID, nutrientCode: Int): Action[AnyContent] =
    userAction.async { request =>
      referenceService
        .deleteReferenceEntry(
          request.user.id,
          referenceMapId.transformInto[ReferenceMapId],
          nutrientCode.transformInto[NutrientCode]
        )
        .map(
          _.pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  private def badRequest(serverError: ServerError): Result =
    BadRequest(serverError.asJson)

  private def errorHandler: PartialFunction[Throwable, Result] = { case error =>
    val context = error match {
      case DBError.Reference.MapNotFound =>
        ErrorContext.ReferenceMap.NotFound
      case DBError.Reference.EntryNotFound =>
        ErrorContext.ReferenceMap.Entry.NotFound
      case _ =>
        ErrorContext.ReferenceMap.General(error.getMessage)
    }

    BadRequest(context.asServerError.asJson)
  }

}
