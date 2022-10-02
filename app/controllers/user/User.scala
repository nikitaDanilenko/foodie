package controllers.user

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

import java.util.UUID

@JsonCodec
case class User(
    id: UUID,
    nickname: String,
    displayName: Option[String],
    email: String
)

object User {

  implicit val fromInternal: Transformer[services.user.User, User] =
    Transformer
      .define[services.user.User, User]
      .buildTransformer

}
