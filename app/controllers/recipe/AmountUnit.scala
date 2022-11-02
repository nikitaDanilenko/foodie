package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import services.MeasureId
import utils.TransformerUtils.Implicits._

@JsonCodec
case class AmountUnit(
    measureId: Int,
    factor: BigDecimal
)

object AmountUnit {

  implicit val fromInternal: Transformer[services.recipe.AmountUnit, AmountUnit] = amountUnit =>
    AmountUnit(
      measureId = amountUnit.measureId.getOrElse(services.recipe.AmountUnit.hundredGrams),
      factor = amountUnit.factor
    )

  implicit val toInternal: Transformer[AmountUnit, services.recipe.AmountUnit] = amountUnit =>
    services.recipe.AmountUnit(
      measureId =
        Some(amountUnit.measureId.transformInto[MeasureId]).filter(id => id != services.recipe.AmountUnit.hundredGrams),
      factor = amountUnit.factor
    )

}
