package controllers.user

import action.{ RequestHeaders, UserAction }
import cats.data.{ EitherT, OptionT }
import cats.effect.unsafe.implicits.global
import cats.instances.future._
import errors.{ ErrorContext, ServerError }
import io.circe.Encoder
import io.circe.syntax._
import io.scalaland.chimney.dsl._
import play.api.libs.circe.Circe
import play.api.mvc._
import security.Hash
import security.jwt.{ JwtConfiguration, JwtExpiration, UserContent }
import services.UserId
import services.mail.MailService
import services.user.{ PasswordParameters, User, UserService }
import spire.math.Natural
import utils.TransformerUtils.Implicits._
import utils.jwt.JwtUtil

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
      OptionT(userService.getByNickname(credentials.nickname))
        .subflatMap { user =>
          if (UserController.validateCredentials(credentials, user)) {
            val jwt = JwtUtil.createJwt(
              content = UserContent(
                userId = user.id.transformInto[UUID]
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
        .fold(
          BadRequest("Invalid credentials")
        )(jwt => Ok(jwt.asJson))
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

  def confirmRegistration: Action[UserCreation] =
    Action.async(circe.tolerantJson[UserCreation]) { request =>
      val userCreation = request.body
      toResult("An error occurred while creating the user") {
        for {
          token <- EitherT.fromOption(
            request.headers.get(RequestHeaders.confirmation),
            ErrorContext.User.Confirmation.asServerError
          )
          registrationRequest <- EitherT.fromEither[Future](
            JwtUtil.validateJwt[UserIdentifier](token, jwtConfiguration.signaturePublicKey)
          )
          _ <- EitherT.fromEither(
            if (
              userCreation.email == registrationRequest.email && userCreation.nickname == registrationRequest.nickname
            )
              Right(())
            else Left(ErrorContext.User.Mismatch.asServerError)
          )
          result <- createUser(userCreation)
        } yield result
      }
    }

  def requestRecovery: Action[RecoveryRequest] =
    Action.async(circe.tolerantJson[RecoveryRequest]) { request =>
      val action = for {
        user <- EitherT.fromOptionF(
          userService
            .getByNicknameOrEmail(request.body.identifier),
          ErrorContext.User.NotFound.asServerError
        )
        recoveryJwt = createJwt(UserContent(userId = user.id))
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

  def confirmRecovery: Action[PasswordUpdate] =
    Action.async(circe.tolerantJson[PasswordUpdate]) { request =>
      toResult("An error occurred while creating the user") {
        for {
          token <- EitherT.fromOption(
            request.headers.get(RequestHeaders.confirmation),
            ErrorContext.User.Confirmation.asServerError
          )
          userContent <- EitherT.fromEither[Future](
            JwtUtil.validateJwt[UserContent](token, jwtConfiguration.signaturePublicKey)
          )
          response <-
            EitherT.liftF(userService.updatePassword(userContent.userId.transformInto[UserId], request.body.password))
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
              emailParameters = UserConfiguration.recoveryEmail(
                userConfiguration,
                userIdentifier = UserIdentifier.of(request.user),
                // TODO: UserContent is too wonky - this way one can skip the confirmation!
                jwt = createJwt(UserContent(userId = request.user.id))
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

  private def createUser(userCreation: UserCreation): EitherT[Future, ServerError, Result] =
    for {
      user     <- EitherT.liftF[Future, ServerError, User](UserCreation.create(userCreation))
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
      user: User
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
