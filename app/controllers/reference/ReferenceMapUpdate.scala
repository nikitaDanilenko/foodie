package controllers.reference

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

import java.util.UUID
import utils.TransformerUtils.Implicits._

@JsonCodec
case class ReferenceMapUpdate(
    id: UUID,
    name: String
)

object ReferenceMapUpdate {

  implicit val toInternal: Transformer[ReferenceMapUpdate, services.reference.ReferenceMapUpdate] =
    Transformer
      .define[ReferenceMapUpdate, services.reference.ReferenceMapUpdate]
      .buildTransformer

}
