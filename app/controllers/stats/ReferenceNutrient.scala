package controllers.stats

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import services.reference.ReferenceEntry

@JsonCodec
case class ReferenceNutrient(
    nutrientCode: Int,
    amount: BigDecimal
)

object ReferenceNutrient {

  implicit val fromInternal: Transformer[ReferenceEntry, ReferenceNutrient] =
    Transformer
      .define[ReferenceEntry, ReferenceNutrient]
      .buildTransformer

}
