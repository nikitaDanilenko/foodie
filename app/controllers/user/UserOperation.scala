package controllers.user

import enumeratum.{ CirceEnum, Enum, EnumEntry }
import io.circe.generic.JsonCodec

import java.util.UUID

@JsonCodec
case class UserOperation(
    userId: UUID,
    operation: UserOperation.Operation
)

object UserOperation {
  sealed trait Operation extends EnumEntry

  object Operation extends Enum[Operation] with CirceEnum[Operation] {
    case object Recovery extends Operation
    case object Deletion extends Operation

    override lazy val values: IndexedSeq[Operation] = findValues
  }

}
