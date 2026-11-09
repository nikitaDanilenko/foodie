package utils

import io.scalaland.chimney.Transformer
import java.time.{ LocalDate, LocalTime }

object TransformerUtils {

  object Implicits {

    implicit val localDateToSqlDate: Transformer[LocalDate, java.sql.Date] =
      java.sql.Date.valueOf

    implicit val sqlDateToLocalDate: Transformer[java.sql.Date, LocalDate] =
      _.toLocalDate

    implicit val localTimeToSqlTime: Transformer[LocalTime, java.sql.Time] =
      java.sql.Time.valueOf

    implicit val sqlTimeToLocalTime: Transformer[java.sql.Time, LocalTime] =
      _.toLocalTime

  }

}
