package controllers.reference

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

import java.util.UUID

@JsonCodec
case class ReferenceEntryCreation(
    referenceMapId: UUID,
    nutrientCode: Int,
    amount: BigDecimal
)

object ReferenceEntryCreation {

  implicit val toInternal: Transformer[ReferenceEntryCreation, services.reference.ReferenceEntryCreation] =
    Transformer
      .define[ReferenceEntryCreation, services.reference.ReferenceEntryCreation]
      .buildTransformer

}
