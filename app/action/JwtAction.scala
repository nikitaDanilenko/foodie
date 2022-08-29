package action

import cats.data.EitherT
import errors.{ ErrorContext, ServerError }
import io.circe.syntax._
import io.scalaland.chimney.dsl._
import javax.inject.Inject
import play.api.libs.circe.Circe
import play.api.mvc._
import pureconfig.generic.ProductHint
import pureconfig.{ CamelCase, ConfigFieldMapping }
import security.jwt.{ JwtConfiguration, JwtContent }
import services.UserId
import services.user.{ User, UserService }
import utils.TransformerUtils.Implicits._
import utils.jwt.JwtUtil

import scala.concurrent.{ ExecutionContext, Future }

class JwtAction @Inject() (
    override val parse: PlayBodyParsers,
    userService: UserService
)(implicit override val executionContext: ExecutionContext)
    extends ActionBuilder[UserRequest, AnyContent]
    with ActionRefiner[Request, UserRequest]
    with Circe {

  override protected def refine[A](request: Request[A]): Future[Either[Result, UserRequest[A]]] = {
    val transformer = for {
      token <- EitherT.fromOption[Future](
        request.headers.get(RequestHeaders.userTokenHeader),
        ErrorContext.Authentication.Token.Missing.asServerError
      )
      jwtContent <-
        EitherT.fromEither[Future](JwtUtil.validateJwt[JwtContent](token, JwtConfiguration.default.signaturePublicKey))
      user <- EitherT.fromOptionF[Future, ServerError, User](
        userService
          .get(
            jwtContent.userId.transformInto[UserId]
          ),
        ErrorContext.User.NotFound.asServerError
      )
    } yield UserRequest(
      request = request,
      user = user
    )

    transformer
      .leftMap(error => Results.Unauthorized(error.asJson))
      .value
  }

  override val parser: BodyParser[AnyContent] = new BodyParsers.Default(parse)
}
