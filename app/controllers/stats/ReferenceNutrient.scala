package controllers.stats

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class ReferenceNutrient(
    nutrientCode: Int,
    amount: BigDecimal
)

object ReferenceNutrient {

  implicit val fromInternal: Transformer[services.stats.ReferenceNutrient, ReferenceNutrient] =
    Transformer
      .define[services.stats.ReferenceNutrient, ReferenceNutrient]
      .buildTransformer

}
