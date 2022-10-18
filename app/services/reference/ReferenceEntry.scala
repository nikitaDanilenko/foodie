package services.reference

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import services.{ NutrientCode, ReferenceMapId }
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class ReferenceEntry(
    nutrientCode: NutrientCode,
    amount: BigDecimal
)

object ReferenceEntry {

  implicit val fromDB: Transformer[Tables.ReferenceEntryRow, ReferenceEntry] =
    Transformer
      .define[Tables.ReferenceEntryRow, ReferenceEntry]
      .buildTransformer

  implicit val toDB: Transformer[(ReferenceEntry, ReferenceMapId), Tables.ReferenceEntryRow] = {
    case (referenceEntry, referenceMapId) =>
      Tables.ReferenceEntryRow(
        referenceMapId = referenceMapId.transformInto[UUID],
        nutrientCode = referenceEntry.nutrientCode.transformInto[Int],
        amount = referenceEntry.amount
      )

  }

}
