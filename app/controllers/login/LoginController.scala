package controllers.login

import cats.data.{ EitherT, OptionT }
import cats.effect.unsafe.implicits.global
import errors.ServerError
import io.circe.syntax._
import javax.inject.Inject
import play.api.libs.circe.Circe
import play.api.mvc.{ AbstractController, Action, ControllerComponents }
import security.Hash
import security.jwt.{ JwtConfiguration, JwtExpiration }
import services.user.{ PasswordParameters, User, UserService }
import spire.math.Natural
import utils.jwt.JwtUtil

import scala.concurrent.{ ExecutionContext, Future }

class LoginController @Inject() (
    cc: ControllerComponents,
    userService: UserService
)(implicit executionContext: ExecutionContext)
    extends AbstractController(cc)
    with Circe {

  private val jwtConfiguration = JwtConfiguration.default

  def login: Action[Credentials] =
    Action.async(circe.tolerantJson[Credentials]) { request =>
      val credentials = request.body
      OptionT(userService.getByNickname(credentials.nickname))
        .subflatMap { user =>
          if (LoginController.validateCredentials(credentials, user)) {
            val jwt = JwtUtil.createJwt(
              userId = user.id,
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
      val action = for {
        userCreation <- EitherT.fromEither[Future](
          JwtUtil.validateJwt[UserCreation](request.body, jwtConfiguration.signaturePublicKey)
        )
        user     <- EitherT.liftF[Future, ServerError, User](UserCreation.create(userCreation))
        response <- EitherT.liftF[Future, ServerError, Boolean](userService.add(user))
      } yield {
        if (response)
          Ok(s"Created user '${userCreation.nickname}'")
        else
          BadRequest(s"An error occurred while creating the user.")
      }
      action
        .fold(
          error => BadRequest(error.asJson),
          identity
        )
        .recover {
          case ex =>
            BadRequest(s"An error occurred while creating the user: ${ex.getMessage}")
        }
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
