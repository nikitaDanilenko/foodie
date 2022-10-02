package controllers.user

import io.circe.generic.JsonCodec
import services.user.User

@JsonCodec
case class UserIdentifier(
    nickname: String,
    email: String
)

object UserIdentifier {

  def of(user: User): UserIdentifier =
    UserIdentifier(
      nickname = user.nickname,
      email = user.email
    )

}
