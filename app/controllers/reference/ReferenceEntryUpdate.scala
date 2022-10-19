package controllers.reference

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

import java.util.UUID

@JsonCodec
case class ReferenceEntryUpdate(
    referenceMapId: UUID,
    nutrientCode: Int,
    amount: BigDecimal
)

object ReferenceEntryUpdate {

  implicit val toInternal: Transformer[ReferenceEntryUpdate, services.reference.ReferenceEntryUpdate] =
    Transformer
      .define[ReferenceEntryUpdate, services.reference.ReferenceEntryUpdate]
      .buildTransformer

}
