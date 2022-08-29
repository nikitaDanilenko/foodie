package utils.date

import java.time.LocalDate

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class Date(
    year: Int,
    month: Int,
    day: Int
)

object Date {

  implicit val toJava: Transformer[Date, LocalDate] = date =>
    LocalDate.of(
      date.year,
      date.month,
      date.day
    )

  implicit val fromJava: Transformer[LocalDate, Date] = localDate =>
    Date(
      year = localDate.getYear,
      month = localDate.getMonthValue,
      day = localDate.getDayOfMonth
    )

}
