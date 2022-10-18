package controllers.stats

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import services.reference.ReferenceEntryCreation
import utils.TransformerUtils.Implicits._

@JsonCodec
case class ReferenceNutrientCreation(
    nutrientCode: Int,
    amount: BigDecimal
)

object ReferenceNutrientCreation {

  implicit val toInternal: Transformer[ReferenceNutrientCreation, ReferenceEntryCreation] =
    Transformer
      .define[ReferenceNutrientCreation, ReferenceEntryCreation]
      .buildTransformer

}
