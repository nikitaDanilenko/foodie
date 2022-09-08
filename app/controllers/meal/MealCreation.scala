package controllers.meal

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

import utils.date.SimpleDate

@JsonCodec
case class MealCreation(
    date: SimpleDate,
    name: Option[String]
)

object MealCreation {

  implicit val toInternal: Transformer[MealCreation, services.meal.MealCreation] =
    Transformer
      .define[MealCreation, services.meal.MealCreation]
      .buildTransformer

}
