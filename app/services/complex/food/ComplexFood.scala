package services.complex.food

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import services.RecipeId
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class ComplexFood(
    recipeId: RecipeId,
    amount: BigDecimal,
    unit: ComplexFoodUnit
)

object ComplexFood {

  implicit val fromDB: Transformer[Tables.ComplexFoodRow, ComplexFood] =
    row =>
      ComplexFood(
        recipeId = row.recipeId.transformInto[RecipeId],
        amount = row.amount,
        unit = ComplexFoodUnit.withName(row.unit)
      )

  implicit val toDB: Transformer[ComplexFood, Tables.ComplexFoodRow] = complexFood =>
    Tables.ComplexFoodRow(
      recipeId = complexFood.recipeId.transformInto[UUID],
      amount = complexFood.amount,
      unit = complexFood.unit.entryName
    )

}
