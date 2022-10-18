package controllers.stats

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import services.reference.ReferenceEntryUpdate
import utils.TransformerUtils.Implicits._

@JsonCodec
case class ReferenceNutrientUpdate(
    nutrientCode: Int,
    amount: BigDecimal
)

object ReferenceNutrientUpdate {

  implicit val toInternal: Transformer[ReferenceNutrientUpdate, ReferenceEntryUpdate] =
    Transformer
      .define[ReferenceNutrientUpdate, ReferenceEntryUpdate]
      .buildTransformer

}
