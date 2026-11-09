package controllers.stats

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._

@JsonCodec
case class NutrientInformationBase(
    nutrientCode: Int,
    name: String,
    symbol: String,
    unit: NutrientUnit
)

object NutrientInformationBase {

  implicit val fromDomain: Transformer[services.nutrient.Nutrient, NutrientInformationBase] = nutrient =>
    NutrientInformationBase(
      nutrientCode = nutrient.code.transformInto[Int],
      name = nutrient.name,
      symbol = nutrient.symbol,
      unit = nutrient.unit.transformInto[NutrientUnit]
    )

}
