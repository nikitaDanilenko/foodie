package controllers.stats

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

@JsonCodec
case class ReferenceNutrientUpdate(
    nutrientCode: Int,
    amount: BigDecimal
)

object ReferenceNutrientUpdate {

  implicit val toInternal: Transformer[ReferenceNutrientUpdate, services.stats.ReferenceNutrientUpdate] =
    Transformer
      .define[ReferenceNutrientUpdate, services.stats.ReferenceNutrientUpdate]
      .buildTransformer

}
