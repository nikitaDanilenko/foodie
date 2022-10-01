package controllers.login

import action.RequestHeaders
import cats.data.{ EitherT, OptionT }
import cats.effect.unsafe.implicits.global
import cats.instances.future._
import errors.{ ErrorContext, ServerError }
import io.circe.syntax._
import io.scalaland.chimney.dsl._
import play.api.libs.circe.Circe
import play.api.mvc.{ AbstractController, Action, ControllerComponents, Result }
import security.Hash
import security.jwt.{ JwtConfiguration, JwtExpiration, UserContent }
import services.mail.MailService
import services.user.{ PasswordParameters, User, UserService }
import spire.math.Natural
import utils.TransformerUtils.Implicits._
import utils.jwt.JwtUtil

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

class LoginController @Inject() (
    cc: ControllerComponents,
    userService: UserService,
    mailService: MailService
)(implicit executionContext: ExecutionContext)
    extends AbstractController(cc)
    with Circe {

  private val jwtConfiguration = JwtConfiguration.default

  private val registrationConfiguration = RegistrationConfiguration.default

  def login: Action[Credentials] =
    Action.async(circe.tolerantJson[Credentials]) { request =>
      val credentials = request.body
      OptionT(userService.getByNickname(credentials.nickname))
        .subflatMap { user =>
          if (LoginController.validateCredentials(credentials, user)) {
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

  def createUser: Action[String] =
    Action.async(circe.tolerantJson[String]) { request =>
      toResult("An error occurred while creating the user") {
        EitherT
          .fromEither[Future](
            JwtUtil.validateJwt[UserCreation](request.body, jwtConfiguration.signaturePublicKey)
          )
          .flatMap(createUser)
      }
    }

  def requestRegistration: Action[RegistrationRequest] =
    Action.async(circe.tolerantJson[RegistrationRequest]) { request =>
      val registrationRequest = request.body
      val action = for {
        _ <- EitherT.fromOptionF(
          userService
            .getByNickname(registrationRequest.nickname)
            .map(r => if (r.isDefined) None else Some(())),
          ErrorContext.User.Exists.asServerError
        )
        registrationJwt = JwtUtil.createJwt(
          content = registrationRequest,
          privateKey = jwtConfiguration.signaturePrivateKey,
          expiration = JwtExpiration.Expiring(
            start = System.currentTimeMillis() / 1000,
            duration = registrationConfiguration.restrictedDurationInSeconds
          )
        )
        _ <- EitherT(
          mailService
            .sendEmail(
              emailParameters = RegistrationConfiguration.email(
                registrationConfiguration = registrationConfiguration,
                registrationRequest = registrationRequest,
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
            JwtUtil.validateJwt[RegistrationRequest](token, jwtConfiguration.signaturePublicKey)
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

  private def createUser(userCreation: UserCreation): EitherT[Future, ServerError, Result] =
    for {
      user     <- EitherT.liftF[Future, ServerError, User](UserCreation.create(userCreation))
      response <- EitherT.liftF[Future, ServerError, Boolean](userService.add(user))
    } yield
      if (response)
        Ok(s"Created user '${userCreation.nickname}'")
      else
        BadRequest(s"An error occurred while creating the user.")

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

object LoginController {

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
