package controllers.stats

import io.circe.generic.JsonCodec

@JsonCodec
case class Values(
    total: BigDecimal,
    dailyAverage: BigDecimal
)
