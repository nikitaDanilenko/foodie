package controllers.meal

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

import java.util.UUID
import utils.date.SimpleDate

@JsonCodec
case class Meal(
    id: UUID,
    date: SimpleDate,
    name: Option[String]
)

object Meal {

  implicit val fromInternal: Transformer[services.meal.Meal, Meal] =
    Transformer
      .define[services.meal.Meal, Meal]
      .buildTransformer

}
