package services.recipe

import io.scalaland.chimney.dsl._
import services.MeasureId
import utils.TransformerUtils.Implicits._

case class AmountUnit(
    measureId: Option[MeasureId],
    factor: BigDecimal
)

object AmountUnit {
  val hundredGrams: MeasureId = 1455.transformInto[MeasureId]
}
