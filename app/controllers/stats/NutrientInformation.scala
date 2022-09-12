package controllers.stats

import io.circe.generic.JsonCodec

@JsonCodec
case class NutrientInformation(
    nutrientCode: Int,
    name: String,
    symbol: String,
    unit: NutrientUnit,
    amounts: Amounts
)
