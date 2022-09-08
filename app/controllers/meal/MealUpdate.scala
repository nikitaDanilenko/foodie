package controllers.meal

import java.util.UUID

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

import utils.date.SimpleDate

@JsonCodec
case class MealUpdate(
    id: UUID,
    date: SimpleDate,
    name: Option[String]
)

object MealUpdate {

  implicit val toDomain: Transformer[MealUpdate, services.meal.MealUpdate] =
    Transformer
      .define[MealUpdate, services.meal.MealUpdate]
      .buildTransformer

}
