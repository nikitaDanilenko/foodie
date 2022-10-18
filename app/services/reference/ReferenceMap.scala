package services.reference

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import services.{ReferenceMapId, UserId}
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class ReferenceMap(
    id: ReferenceMapId,
    name: String
)

object ReferenceMap {

  implicit val fromDB: Transformer[Tables.ReferenceMapRow, ReferenceMap] =
    Transformer
      .define[Tables.ReferenceMapRow, ReferenceMap]
      .buildTransformer

  implicit val toDB: Transformer[(ReferenceMap, UserId), Tables.ReferenceMapRow] = {
    case (referenceMap, userId) =>
      Tables.ReferenceMapRow(
        id = referenceMap.id.transformInto[UUID],
        userId = userId.transformInto[UUID],
        name = referenceMap.name
      )
  }

}
