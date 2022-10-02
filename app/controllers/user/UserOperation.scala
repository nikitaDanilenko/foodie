package controllers.user

import io.circe.generic.JsonCodec

import java.util.UUID

@JsonCodec
case class UserOperation[O](
    userId: UUID,
    operation: O
)

object UserOperation {

  @JsonCodec
  sealed trait Recovery

  case object Recovery extends Recovery

  @JsonCodec
  sealed trait Deletion

  case object Deletion extends Deletion

}
