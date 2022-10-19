package controllers.reference

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._

@JsonCodec
case class ReferenceTree(
    referenceMap: ReferenceMap,
    nutrients: Seq[ReferenceValue]
)

object ReferenceTree {

  implicit val fromDB: Transformer[services.reference.ReferenceTree, ReferenceTree] = referenceTree =>
    ReferenceTree(
      referenceTree.referenceMap.transformInto[ReferenceMap],
      nutrients = referenceTree.nutrientMap.map {
        case (nutrient, amount) =>
          ReferenceValue(
            nutrientCode = nutrient.code.transformInto[Int],
            referenceAmount = amount
          )
      }.toSeq
    )

}
