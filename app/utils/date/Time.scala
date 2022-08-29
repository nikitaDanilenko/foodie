package utils.date

import java.time.LocalTime

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class Time(
    hour: Int,
    minute: Int
)

object Time {

  implicit val toJava: Transformer[Time, LocalTime] =
    time => LocalTime.of(time.hour, time.minute)

  implicit val fromJava: Transformer[LocalTime, Time] = localTime =>
    Time(
      hour = localTime.getHour,
      minute = localTime.getMinute
    )

}
