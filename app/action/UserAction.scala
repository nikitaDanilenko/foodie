package action

import cats.data.EitherT
import errors.{ ErrorContext, ServerError }
import io.circe.syntax._
import io.scalaland.chimney.dsl._
import play.api.libs.circe.Circe
import play.api.mvc._
import security.jwt.{ JwtConfiguration, LoginContent }
import services.user.{ User, UserService }
import services.{ SessionId, UserId }
import utils.TransformerUtils.Implicits._
import utils.jwt.JwtUtil

import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

class UserAction @Inject() (
    override val parse: PlayBodyParsers,
    userService: UserService
)(implicit override val executionContext: ExecutionContext)
    extends ActionBuilder[UserRequest, AnyContent]
    with ActionRefiner[Request, UserRequest]
    with Circe {

  override protected def refine[A](request: Request[A]): Future[Either[Result, UserRequest[A]]] = {
    val transformer = for {
      token <- EitherT.fromOption[Future](
        request.headers.get(RequestHeaders.userToken),
        ErrorContext.Authentication.Token.Missing.asServerError
      )
      loginContent <- EitherT.fromEither[Future](
        JwtUtil.validateJwt[LoginContent](token, JwtConfiguration.default.signaturePublicKey)
      )
      userId    = loginContent.userId.transformInto[UserId]
      sessionId = loginContent.sessionId.transformInto[SessionId]
      _ <- EitherT(
        userService
          .existsSession(
            userId = userId,
            sessionId = sessionId
          )
          .map { exists =>
            if (exists)
              Right(())
            else Left(ErrorContext.Login.Session.asServerError)
          }
      )
      user <- EitherT.fromOptionF[Future, ServerError, User](
        userService.get(userId),
        ErrorContext.User.NotFound.asServerError
      )
    } yield UserRequest(
      request = request,
      user = user,
      sessionId = sessionId
    )

    transformer
      .leftMap(error => Results.Unauthorized(error.asJson))
      .value
  }

  override val parser: BodyParser[AnyContent] = new BodyParsers.Default(parse)
}
