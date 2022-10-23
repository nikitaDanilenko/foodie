package services.complex.ingredient

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import services.{ ComplexFoodId, RecipeId }
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class ComplexIngredient(
    recipeId: RecipeId,
    complexFoodId: ComplexFoodId,
    factor: BigDecimal
)

object ComplexIngredient {

  implicit val fromDB: Transformer[Tables.ComplexIngredientRow, ComplexIngredient] =
    row =>
      ComplexIngredient(
        recipeId = row.recipeId.transformInto[RecipeId],
        complexFoodId = row.complexFoodId.transformInto[ComplexFoodId],
        factor = row.factor
      )

  implicit val toDB: Transformer[ComplexIngredient, Tables.ComplexIngredientRow] = complexIngredient =>
    Tables.ComplexIngredientRow(
      recipeId = complexIngredient.recipeId.transformInto[UUID],
      complexFoodId = complexIngredient.complexFoodId.transformInto[UUID],
      factor = complexIngredient.factor
    )

}
