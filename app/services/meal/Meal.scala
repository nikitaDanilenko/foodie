package services.meal

import db.generated.Tables
import db.{ MealId, ProfileId, UserId }
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import utils.TransformerUtils.Implicits._
import utils.date.{ Date, SimpleDate, Time }

import java.time.{ LocalDate, LocalTime }
import java.util.UUID

case class Meal(
    id: MealId,
    date: SimpleDate,
    name: Option[String]
)

object Meal {

  implicit val fromDB: Transformer[Tables.MealRow, Meal] =
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

  case class TransformableToDB(
      userId: UserId,
      profileId: ProfileId,
      meal: Meal
  )

  implicit val toDB: Transformer[TransformableToDB, Tables.MealRow] = { transformableToDB =>
    Tables.MealRow(
      id = transformableToDB.meal.id.transformInto[UUID],
      userId = transformableToDB.userId.transformInto[UUID],
      profileId = transformableToDB.profileId.transformInto[UUID],
      consumedOnDate = transformableToDB.meal.date.date.transformInto[LocalDate].transformInto[java.sql.Date],
      consumedOnTime = transformableToDB.meal.date.time.map(_.transformInto[LocalTime].transformInto[java.sql.Time]),
      name = transformableToDB.meal.name
    )
  }

}
