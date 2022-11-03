package controllers.stats

import io.circe.generic.JsonCodec

@JsonCodec
case class Amounts(
    total: Option[BigDecimal],
    dailyAverage: Option[BigDecimal],
    numberOfIngredients: Int,
    numberOfDefinedValues: Int
)
