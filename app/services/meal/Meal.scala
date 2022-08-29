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
    name: Option[String],
    entries: Seq[MealEntry]
)

object Meal {

  case class DBRepresentation(
      mealRow: Tables.MealRow,
      mealEntryRows: Seq[Tables.MealEntryRow]
  )

  implicit val fromRepresentation: Transformer[DBRepresentation, Meal] =
    Transformer
      .define[DBRepresentation, Meal]
      .withFieldComputed(_.id, _.mealRow.id.transformInto[MealId])
      .withFieldComputed(
        _.date,
        r =>
          SimpleDate(
            r.mealRow.consumedOnDate.toLocalDate.transformInto[Date],
            r.mealRow.consumedOnTime.map(_.toLocalTime.transformInto[Time])
          )
      )
      .withFieldComputed(_.name, _.mealRow.name)
      .withFieldComputed(_.entries, _.mealEntryRows.map(_.transformInto[MealEntry]))
      .buildTransformer

  implicit val toRepresentation: Transformer[(Meal, UserId), DBRepresentation] = {
    case (meal, userId) =>
      DBRepresentation(
        mealRow = Tables.MealRow(
          id = meal.id.transformInto[UUID],
          userId = userId.transformInto[UUID],
          consumedOnDate = meal.date.date.transformInto[LocalDate].transformInto[java.sql.Date],
          consumedOnTime = meal.date.time.map(_.transformInto[LocalTime].transformInto[java.sql.Time]),
          name = meal.name
        ),
        mealEntryRows = meal.entries.map(me => (me, meal.id).transformInto[Tables.MealEntryRow])
      )
  }

}
