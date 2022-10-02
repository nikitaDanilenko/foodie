package controllers.user

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class UserUpdate(
    displayName: Option[String]
)

object UserUpdate {

  implicit val toInternal: Transformer[(UserUpdate, services.user.User), services.user.UserUpdate] = {
    case (userUpdate, user) =>
      services.user.UserUpdate(
        displayName = userUpdate.displayName,
        email = user.email
      )
  }

}
