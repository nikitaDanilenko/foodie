package services.complex

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._
import services.RecipeId

import java.util.UUID

case class ComplexIngredient(
    recipeId: RecipeId,
    amount: BigDecimal,
    unit: ComplexIngredientUnit
)

object ComplexIngredient {

  implicit val fromDB: Transformer[Tables.ComplexIngredientRow, ComplexIngredient] =
    row =>
      ComplexIngredient(
        recipeId = row.recipeId.transformInto[RecipeId],
        amount = row.amount,
        unit = ComplexIngredientUnit.withName(row.unit)
      )

  implicit val toDB: Transformer[ComplexIngredient, Tables.ComplexIngredientRow] = complexIngredient =>
    Tables.ComplexIngredientRow(
      recipeId = complexIngredient.recipeId.transformInto[UUID],
      amount = complexIngredient.amount,
      unit = complexIngredient.unit.entryName
    )

}
