package controllers.reference

import io.circe.generic.JsonCodec

@JsonCodec
case class ReferenceValue(
    nutrientCode: Int,
    referenceAmount: BigDecimal
)
