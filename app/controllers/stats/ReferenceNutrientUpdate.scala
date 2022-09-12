package controllers.stats

import io.circe.generic.JsonCodec

@JsonCodec
case class ReferenceNutrientUpdate(
    nutrientCode: Int,
    amount: BigDecimal
)
