package controllers.user

import action.{ RequestHeaders, UserAction }
import cats.data.{ EitherT, OptionT }
import cats.effect.unsafe.implicits.global
import cats.instances.future._
import controllers.user.LogoutRequest.Mode
import errors.{ ErrorContext, ServerError }
import io.circe.Encoder
import io.circe.syntax._
import io.scalaland.chimney.dsl._
import play.api.libs.circe.Circe
import play.api.mvc._
import security.Hash
import security.jwt.{ JwtConfiguration, JwtExpiration, LoginContent }
import services.UserId
import services.mail.MailService
import services.user.{ PasswordParameters, UserService }
import spire.math.Natural
import utils.TransformerUtils.Implicits._
import utils.jwt.JwtUtil

import scala.util.chaining._
import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

class UserController @Inject() (
    cc: ControllerComponents,
    userService: UserService,
    mailService: MailService,
    userAction: UserAction
)(implicit executionContext: ExecutionContext)
    extends AbstractController(cc)
    with Circe {

  private val jwtConfiguration = JwtConfiguration.default

  private val userConfiguration = UserConfiguration.default

  def login: Action[Credentials] =
    Action.async(circe.tolerantJson[Credentials]) { request =>
      val credentials = request.body
      val transformer = for {
        user      <- OptionT(userService.getByNickname(credentials.nickname))
        sessionId <- OptionT.liftF(userService.addSession(user.id))
        jwt <- OptionT.fromOption {
          if (UserController.validateCredentials(credentials, user)) {
            val jwt = JwtUtil.createJwt(
              content = LoginContent(
                userId = user.id.transformInto[UUID],
                sessionId = sessionId.transformInto[UUID],
                nickname = user.nickname
              ),
              privateKey = jwtConfiguration.signaturePrivateKey,
              expiration = JwtExpiration.Expiring(
                start = System.currentTimeMillis() / 1000,
                duration = jwtConfiguration.restrictedDurationInSeconds
              )
            )
            Some(jwt)
          } else None
        }
      } yield jwt

      transformer
        .fold(
          BadRequest(ErrorContext.User.InvalidCredentials.asServerError.asJson)
        )(
          _.pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  def logout: Action[LogoutRequest] =
    userAction.async(circe.tolerantJson[LogoutRequest]) { request =>
      (request.body.mode match {
        case Mode.This => userService.deleteSession(request.user.id, request.sessionId)
        case Mode.All  => userService.deleteAllSessions(request.user.id)
      }).map(
        _.pipe(_.asJson)
          .pipe(Ok(_))
      ).recover {
        case error =>
          BadRequest(s"Error during logout: ${error.getMessage}")
      }
    }

  // TODO: Remove after testing
  def create: Action[String] =
    Action.async(circe.tolerantJson[String]) { request =>
      toResult("An error occurred while creating the user") {
        EitherT
          .fromEither[Future](
            JwtUtil.validateJwt[UserCreation](request.body, jwtConfiguration.signaturePublicKey)
          )
          .flatMap(createUser)
      }
    }

  def update: Action[UserUpdate] =
    userAction.async(circe.tolerantJson[UserUpdate]) { request =>
      userService
        .update(request.user.id, (request.body, request.user).transformInto[services.user.UserUpdate])
        .map(
          _.pipe(_.transformInto[User])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  def fetch: Action[AnyContent] =
    userAction {
      _.pipe(_.user)
        .pipe(_.transformInto[User])
        .pipe(_.asJson)
        .pipe(Ok(_))
    }

  def updatePassword: Action[PasswordChangeRequest] =
    userAction.async(circe.tolerantJson[PasswordChangeRequest]) { request =>
      userService
        .updatePassword(
          userId = request.user.id,
          password = request.body.password
        )
        .map { response =>
          if (response) Ok
          else BadRequest(ErrorContext.User.PasswordUpdate.asServerError.asJson)
        }
    }

  def requestRegistration: Action[UserIdentifier] =
    Action.async(circe.tolerantJson[UserIdentifier]) { request =>
      val userIdentifier = request.body
      val action = for {
        _ <- EitherT.fromOptionF(
          userService
            .getByNickname(userIdentifier.nickname)
            .map(r => if (r.isDefined) None else Some(())),
          ErrorContext.User.Exists.asServerError
        )
        registrationJwt = createJwt(userIdentifier)
        _ <- EitherT(
          mailService
            .sendEmail(
              emailParameters = UserConfiguration.registrationEmail(
                userConfiguration = userConfiguration,
                userIdentifier = userIdentifier,
                jwt = registrationJwt
              )
            )
            .map(Right(_))
            .recover {
              case _ =>
                Left(ErrorContext.Mail.SendingFailed.asServerError)
            }
        )
      } yield ()

      action.fold(
        error => BadRequest(error.asJson),
        _ => Ok
      )
    }

  def confirmRegistration: Action[CreationComplement] =
    Action.async(circe.tolerantJson[CreationComplement]) { request =>
      val creationComplement = request.body
      toResult("An error occurred while creating the user") {
        for {
          token <- EitherT.fromOption(
            request.headers.get(RequestHeaders.userToken),
            ErrorContext.User.Confirmation.asServerError
          )
          registrationRequest <- EitherT.fromEither[Future](
            JwtUtil.validateJwt[UserIdentifier](token, jwtConfiguration.signaturePublicKey)
          )
          userCreation = UserCreation(
            nickname = registrationRequest.nickname,
            password = creationComplement.password,
            displayName = creationComplement.displayName,
            email = registrationRequest.email
          )
          result <- createUser(userCreation)
        } yield result
      }
    }

  def find(searchString: String): Action[AnyContent] =
    Action.async {
      userService
        .getByIdentifier(searchString)
        .map(
          _.map(_.transformInto[User])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover {
          case error =>
            BadRequest(error.getMessage)
        }
    }

  def requestRecovery: Action[RecoveryRequest] =
    Action.async(circe.tolerantJson[RecoveryRequest]) { request =>
      val action = for {
        user <- EitherT.fromOptionF(
          userService
            .get(request.body.userId.transformInto[UserId]),
          ErrorContext.User.NotFound.asServerError
        )
        recoveryJwt = createJwt(
          UserOperation(
            userId = user.id,
            operation = UserOperation.Operation.Recovery
          )
        )
        _ <- EitherT(
          mailService
            .sendEmail(
              emailParameters = UserConfiguration.recoveryEmail(
                userConfiguration,
                userIdentifier = UserIdentifier.of(user),
                jwt = recoveryJwt
              )
            )
            .map(Right(_))
            .recover {
              case _ =>
                Left(ErrorContext.Mail.SendingFailed.asServerError)
            }
        )
      } yield ()

      action.fold(
        error => BadRequest(error.asJson),
        _ => Ok
      )
    }

  def confirmRecovery: Action[PasswordChangeRequest] =
    Action.async(circe.tolerantJson[PasswordChangeRequest]) { request =>
      toResult("An error occurred while creating the user") {
        for {
          token <- EitherT.fromOption(
            request.headers.get(RequestHeaders.userToken),
            ErrorContext.User.Confirmation.asServerError
          )
          userRecovery <- EitherT.fromEither[Future](
            JwtUtil
              .validateJwt[UserOperation[UserOperation.Operation.Recovery]](token, jwtConfiguration.signaturePublicKey)
          )
          response <-
            EitherT.liftF(userService.updatePassword(userRecovery.userId.transformInto[UserId], request.body.password))
        } yield
          if (response)
            Ok("Password updated")
          else
            BadRequest(s"An error occurred while recovering the user.")
      }
    }

  def requestDeletion: Action[AnyContent] =
    userAction.async { request =>
      val action = for {
        _ <- EitherT(
          mailService
            .sendEmail(
              emailParameters = UserConfiguration.deletionEmail(
                userConfiguration,
                userIdentifier = UserIdentifier.of(request.user),
                jwt = createJwt(
                  UserOperation(
                    userId = request.user.id,
                    operation = UserOperation.Operation.Deletion
                  )
                )
              )
            )
            .map(Right(_))
            .recover {
              case _ =>
                Left(ErrorContext.Mail.SendingFailed.asServerError)
            }
        )
      } yield ()

      action.fold(
        error => BadRequest(error.asJson),
        _ => Ok
      )
    }

  def confirmDeletion: Action[AnyContent] =
    Action.async { request =>
      toResult("An error occurred while deleting the user") {
        for {
          token <- EitherT.fromOption(
            request.headers.get(RequestHeaders.userToken),
            ErrorContext.User.Confirmation.asServerError
          )
          userDeletion <- EitherT.fromEither[Future](
            JwtUtil
              .validateJwt[UserOperation[UserOperation.Operation.Deletion]](token, jwtConfiguration.signaturePublicKey)
          )
          response <- EitherT.liftF(userService.delete(userDeletion.userId.transformInto[UserId]))
        } yield
          if (response)
            Ok("User deleted")
          else
            BadRequest(s"An error occurred while deleting the user.")
      }
    }

  private def createUser(userCreation: UserCreation): EitherT[Future, ServerError, Result] =
    for {
      user     <- EitherT.liftF[Future, ServerError, services.user.User](UserCreation.create(userCreation))
      response <- EitherT.liftF[Future, ServerError, Boolean](userService.add(user))
    } yield
      if (response)
        Ok(s"Created user '${userCreation.nickname}'")
      else
        BadRequest(s"An error occurred while creating the user.")

  private def createJwt[C: Encoder](content: C) =
    JwtUtil.createJwt(
      content = content,
      privateKey = jwtConfiguration.signaturePrivateKey,
      expiration = JwtExpiration.Expiring(
        start = System.currentTimeMillis() / 1000,
        duration = userConfiguration.restrictedDurationInSeconds
      )
    )

  private def toResult(context: String)(transformer: EitherT[Future, ServerError, Result]): Future[Result] =
    transformer
      .fold(
        error => BadRequest(error.asJson),
        identity
      )
      .recover {
        case ex =>
          BadRequest(s"$context: ${ex.getMessage}")
      }

}

object UserController {

  val iterations: Natural = Natural(120000)

  def validateCredentials(
      credentials: Credentials,
      user: services.user.User
  ): Boolean =
    Hash.verify(
      password = credentials.password,
      passwordParameters = PasswordParameters(
        hash = user.hash,
        salt = user.salt,
        iterations = iterations
      )
    )

}
