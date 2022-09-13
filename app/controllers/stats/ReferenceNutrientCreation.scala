package controllers.stats

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

@JsonCodec
case class ReferenceNutrientCreation(
    nutrientCode: Int,
    amount: BigDecimal
)

object ReferenceNutrientCreation {

  implicit val toInternal: Transformer[ReferenceNutrientCreation, services.stats.ReferenceNutrientCreation] =
    Transformer
      .define[ReferenceNutrientCreation, services.stats.ReferenceNutrientCreation]
      .buildTransformer

}
