package controllers.meal

import action.UserAction
import cats.data.{ EitherT, OptionT }
import db.{ MealEntryId, MealId, ProfileId }
import errors.{ ErrorContext, ServerError }
import io.circe.syntax._
import io.scalaland.chimney.dsl.TransformerOps
import play.api.libs.circe.Circe
import play.api.mvc._
import services.DBError
import services.common.RequestInterval
import services.meal.MealService
import utils.TransformerUtils.Implicits._
import utils.date.SimpleDate

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.ExecutionContext
import scala.util.chaining._

class MealController @Inject() (
    controllerComponents: ControllerComponents,
    mealService: MealService,
    mealDuplication: services.duplication.meal.Duplication,
    userAction: UserAction
)(implicit ec: ExecutionContext)
    extends AbstractController(controllerComponents)
    with Circe {

  def all(profileId: UUID): Action[AnyContent] =
    userAction.async { request =>
      mealService
        .allMeals(
          userId = request.user.id,
          profileId = profileId.transformInto[ProfileId],
          interval = RequestInterval(from = None, to = None).transformInto[services.common.RequestInterval]
        )
        .map(
          _.pipe(
            _.map(_.transformInto[Meal])
          )
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def get(profileId: UUID, mealId: UUID): Action[AnyContent] =
    userAction.async { request =>
      OptionT(mealService.getMeal(request.user.id, profileId.transformInto[ProfileId], mealId.transformInto[MealId]))
        .fold(
          NotFound(ErrorContext.Meal.NotFound.asServerError.asJson): Result
        )(
          _.pipe(_.transformInto[Meal])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def create(profileId: UUID): Action[MealCreation] =
    userAction.async(circe.tolerantJson[MealCreation]) { request =>
      EitherT(
        mealService
          .createMeal(
            request.user.id,
            profileId.transformInto[ProfileId],
            request.body.transformInto[services.meal.MealCreation]
          )
      )
        .map(
          _.pipe(_.transformInto[Meal])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .fold(badRequest, identity)
        .recover(errorHandler)
    }

  def update(profileId: UUID, mealId: UUID): Action[MealUpdate] =
    userAction.async(circe.tolerantJson[MealUpdate]) { request =>
      EitherT(
        mealService
          .updateMeal(
            request.user.id,
            profileId.transformInto[ProfileId],
            mealId.transformInto[MealId],
            request.body.transformInto[services.meal.MealUpdate]
          )
      )
        .map(
          _.pipe(_.transformInto[Meal])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .fold(badRequest, identity)
        .recover(errorHandler)
    }

  def delete(profileId: UUID, mealId: UUID): Action[AnyContent] =
    userAction.async { request =>
      mealService
        .deleteMeal(request.user.id, profileId.transformInto[ProfileId], mealId.transformInto[MealId])
        .map(
          _.pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def getMealEntries(profileId: UUID, mealId: UUID): Action[AnyContent] =
    userAction.async { request =>
      mealService
        .getMealEntries(
          request.user.id,
          profileId.transformInto[ProfileId],
          Seq(mealId.transformInto[MealId])
        )
        .map(
          _.pipe(_.values)
            .pipe(_.flatten)
            .pipe(_.map(_.transformInto[MealEntry]).asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def duplicate(profileId: UUID, mealId: UUID): Action[SimpleDate] =
    userAction.async(circe.tolerantJson[SimpleDate]) { request =>
      EitherT(
        mealDuplication
          .duplicate(
            userId = request.user.id,
            profileId.transformInto[ProfileId],
            id = mealId.transformInto[MealId],
            timeOfDuplication = request.body
          )
      )
        .map(
          _.pipe(_.transformInto[Meal])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .fold(controllers.badRequest, identity)
        .recover(errorHandler)
    }

  def addMealEntry(profileId: UUID, mealId: UUID): Action[MealEntryCreation] =
    userAction.async(circe.tolerantJson[MealEntryCreation]) { request =>
      EitherT(
        mealService.addMealEntry(
          userId = request.user.id,
          profileId.transformInto[ProfileId],
          mealId = mealId.transformInto[MealId],
          mealEntryCreation = request.body.transformInto[services.meal.MealEntryCreation]
        )
      )
        .fold(
          badRequest,
          _.pipe(_.transformInto[MealEntry])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def updateMealEntry(profileId: UUID, mealId: UUID, mealEntryId: UUID): Action[MealEntryUpdate] =
    userAction.async(circe.tolerantJson[MealEntryUpdate]) { request =>
      EitherT(
        mealService.updateMealEntry(
          userId = request.user.id,
          profileId.transformInto[ProfileId],
          mealId = mealId.transformInto[MealId],
          mealEntryId = mealEntryId.transformInto[MealEntryId],
          mealEntryUpdate = request.body.transformInto[services.meal.MealEntryUpdate]
        )
      )
        .fold(
          badRequest,
          _.pipe(_.transformInto[MealEntry])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(errorHandler)
    }

  def deleteMealEntry(profileId: UUID, mealId: UUID, mealEntryId: UUID): Action[AnyContent] =
    userAction.async { request =>
      mealService
        .removeMealEntry(
          request.user.id,
          profileId.transformInto[ProfileId],
          mealId.transformInto[MealId],
          mealEntryId.transformInto[MealEntryId]
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
      case DBError.Meal.NotFound =>
        ErrorContext.Meal.NotFound
      case DBError.Meal.EntryNotFound =>
        ErrorContext.Meal.Entry.NotFound
      case _ =>
        ErrorContext.Meal.General(error.getMessage)
    }

    BadRequest(context.asServerError.asJson)
  }

}
