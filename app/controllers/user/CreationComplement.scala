package controllers.user

import io.circe.generic.JsonCodec

@JsonCodec
case class CreationComplement(
    displayName: Option[String],
    password: String
)
