package controllers.stats

import io.circe.generic.JsonCodec

@JsonCodec
case class Amounts(
    total: BigDecimal,
    dailyAverage: BigDecimal
)
