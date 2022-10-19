package controllers.reference

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class ReferenceMapCreation(
    name: String
)

object ReferenceMapCreation {

  implicit val toInternal: Transformer[ReferenceMapCreation, services.reference.ReferenceMapCreation] =
    Transformer
      .define[ReferenceMapCreation, services.reference.ReferenceMapCreation]
      .buildTransformer

}
