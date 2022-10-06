package controllers.user

import io.circe.generic.JsonCodec

import java.util.UUID

@JsonCodec
case class RecoveryRequest(
    userId: UUID
)
