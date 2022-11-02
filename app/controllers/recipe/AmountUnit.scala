package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

@JsonCodec
case class AmountUnit(
    measureId: Option[Int],
    factor: BigDecimal
)

object AmountUnit {

  implicit val fromInternal: Transformer[services.recipe.AmountUnit, AmountUnit] =
    Transformer
      .define[services.recipe.AmountUnit, AmountUnit]
      .buildTransformer

  implicit val toInternal: Transformer[AmountUnit, services.recipe.AmountUnit] =
    Transformer
      .define[AmountUnit, services.recipe.AmountUnit]
      .buildTransformer

}
