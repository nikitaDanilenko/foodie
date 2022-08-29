package controllers.login

import cats.effect.unsafe.IORuntime
import io.circe.generic.JsonCodec
import io.scalaland.chimney.dsl._
import security.Hash
import services.UserId
import services.user.User
import spire.math.Natural
import utils.TransformerUtils.Implicits._
import utils.random.RandomGenerator

import scala.concurrent.Future

@JsonCodec
case class UserCreation(
    nickname: String,
    password: String,
    displayName: Option[String],
    email: String
)

object UserCreation {
  val saltLength: Natural = Natural(40)

  def create(userCreation: UserCreation)(implicit IORuntime: IORuntime): Future[User] = {
    val action = for {
      id   <- RandomGenerator.randomUUID
      salt <- RandomGenerator.randomAlphaNumericString(saltLength)
    } yield {
      User(
        id = id.transformInto[UserId],
        nickname = userCreation.nickname,
        displayName = userCreation.displayName,
        email = userCreation.email,
        salt = salt,
        hash = Hash.fromPassword(
          userCreation.password,
          salt,
          Hash.defaultIterations
        )
      )
    }
    action.unsafeToFuture()
  }

}
