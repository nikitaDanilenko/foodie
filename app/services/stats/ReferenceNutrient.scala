package services.stats

import java.util.UUID

import db.generated.Tables
import io.scalaland.chimney.Transformer
import services.{ NutrientCode, UserId }
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._

case class ReferenceNutrient(
    nutrientCode: NutrientCode,
    amount: BigDecimal
)

object ReferenceNutrient {

  implicit val fromDB: Transformer[Tables.ReferenceNutrientRow, ReferenceNutrient] =
    Transformer
      .define[Tables.ReferenceNutrientRow, ReferenceNutrient]
      .buildTransformer

  implicit val toDB: Transformer[(ReferenceNutrient, UserId), Tables.ReferenceNutrientRow] = {
    case (referenceNutrient, userId) =>
      Tables.ReferenceNutrientRow(
        userId = userId.transformInto[UUID],
        nutrientCode = referenceNutrient.nutrientCode.transformInto[Int],
        amount = referenceNutrient.amount
      )

  }

}
