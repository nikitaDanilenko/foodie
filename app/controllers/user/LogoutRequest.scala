package controllers.user

import enumeratum.{ CirceEnum, EnumEntry, Enum }
import io.circe.generic.JsonCodec

@JsonCodec
case class LogoutRequest(
    mode: LogoutRequest.Mode
)

object LogoutRequest {
  sealed trait Mode extends EnumEntry

  object Mode extends Enum[Mode] with CirceEnum[Mode] {
    case object This extends Mode
    case object All  extends Mode

    override lazy val values: IndexedSeq[Mode] = findValues
  }

}
