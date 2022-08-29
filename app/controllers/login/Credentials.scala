package controllers.login

import io.circe.generic.JsonCodec

@JsonCodec
case class Credentials(
    nickname: String,
    password: String
)
