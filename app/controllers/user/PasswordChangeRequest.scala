package controllers.user

import io.circe.generic.JsonCodec

@JsonCodec
case class PasswordChangeRequest(
    password: String
)
