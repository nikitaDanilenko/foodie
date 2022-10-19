package controllers.reference

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

@JsonCodec
case class ReferenceEntry(
    nutrientCode: Int,
    amount: BigDecimal
)

object ReferenceEntry {

  implicit val fromInternal: Transformer[services.reference.ReferenceEntry, ReferenceEntry] =
    Transformer
      .define[services.reference.ReferenceEntry, ReferenceEntry]
      .buildTransformer

}
