package controllers.meal

import io.circe.generic.JsonCodec
import java.util.UUID

import utils.date.SimpleDate

@JsonCodec
case class Meal(
    id: UUID,
    date: SimpleDate,
    name: Option[String],
    entries: Seq[MealEntry]
)
