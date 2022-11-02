package services.recipe

import services.MeasureId

case class AmountUnit(
    measureId: Option[MeasureId],
    factor: BigDecimal
)
