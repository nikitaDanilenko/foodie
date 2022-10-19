package controllers.reference

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

import java.util.UUID

@JsonCodec
case class ReferenceMap(
    id: UUID,
    name: String
)

object ReferenceMap {

  implicit val fromInternal: Transformer[services.reference.ReferenceMap, ReferenceMap] =
    Transformer
      .define[services.reference.ReferenceMap, ReferenceMap]
      .buildTransformer

}
