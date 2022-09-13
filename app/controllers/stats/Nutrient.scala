package controllers.stats

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class Nutrient(
    id: Int,
    code: Int,
    symbol: String,
    unit: NutrientUnit,
    name: String,
    nameFrench: String,
    tagName: Option[String],
    decimals: Int
)

object Nutrient {

  implicit val fromInternal: Transformer[services.nutrient.Nutrient, Nutrient] =
    Transformer
      .define[services.nutrient.Nutrient, Nutrient]
      .withFieldComputed(_.decimals, _.decimals.intValue)
      .buildTransformer

}
