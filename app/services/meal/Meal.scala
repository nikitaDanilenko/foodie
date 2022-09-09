package services.meal

import java.time.{ LocalDate, LocalTime }

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import services.{ MealId, UserId }
import utils.TransformerUtils.Implicits._
import java.util.UUID

import utils.date.{ Date, SimpleDate, Time }

case class Meal(
    id: MealId,
    date: SimpleDate,
    name: Option[String]
)

object Meal {

  implicit val fromRepresentation: Transformer[Tables.MealRow, Meal] =
    Transformer
      .define[Tables.MealRow, Meal]
      .withFieldComputed(_.id, _.id.transformInto[MealId])
      .withFieldComputed(
        _.date,
        r =>
          SimpleDate(
            r.consumedOnDate.toLocalDate.transformInto[Date],
            r.consumedOnTime.map(_.toLocalTime.transformInto[Time])
          )
      )
      .buildTransformer

  implicit val toRepresentation: Transformer[(Meal, UserId), Tables.MealRow] = {
    case (meal, userId) =>
      Tables.MealRow(
        id = meal.id.transformInto[UUID],
        userId = userId.transformInto[UUID],
        consumedOnDate = meal.date.date.transformInto[LocalDate].transformInto[java.sql.Date],
        consumedOnTime = meal.date.time.map(_.transformInto[LocalTime].transformInto[java.sql.Time]),
        name = meal.name
      )
  }

}
