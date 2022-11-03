package services.stats

import spire.math.Natural

case class Amount(
    value: Option[BigDecimal],
    numberOfIngredients: Natural,
    numberOfDefinedValues: Natural
)
