package controllers.complex

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

import java.util.UUID

@JsonCodec
case class ComplexFood(
    recipeId: UUID,
    amount: BigDecimal,
    unit: ComplexFoodUnit
)

object ComplexFood {

  implicit val toInternal: Transformer[ComplexFood, services.complex.food.ComplexFood] =
    Transformer
      .define[ComplexFood, services.complex.food.ComplexFood]
      .buildTransformer

  implicit val fromInternal: Transformer[services.complex.food.ComplexFood, ComplexFood] =
    Transformer
      .define[services.complex.food.ComplexFood, ComplexFood]
      .buildTransformer

}
