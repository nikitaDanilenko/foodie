package controllers.login

import cats.data.OptionT
import io.circe.syntax._
import javax.inject.Inject
import play.api.libs.circe.Circe
import play.api.mvc.{ AbstractController, Action, ControllerComponents }
import security.Hash
import security.jwt.{ JwtConfiguration, JwtExpiration }
import services.user.{ PasswordParameters, User, UserService }
import spire.math.Natural
import utils.jwt.JwtUtil

import scala.concurrent.ExecutionContext

class LoginController @Inject() (
    cc: ControllerComponents,
    userService: UserService,
    jwtConfiguration: JwtConfiguration
)(implicit executionContext: ExecutionContext)
    extends AbstractController(cc)
    with Circe {

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
