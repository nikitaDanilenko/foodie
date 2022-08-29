package controllers.meal

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import java.util.UUID

import utils.TransformerUtils.Implicits._
import utils.date.SimpleDate

@JsonCodec
case class MealCreation(
    date: SimpleDate,
    name: Option[String],
    recipeId: UUID,
    amount: BigDecimal
)

object MealCreation {

  implicit val toInternal: Transformer[MealCreation, services.meal.MealCreation] =
    Transformer
      .define[MealCreation, services.meal.MealCreation]
      .buildTransformer

}
