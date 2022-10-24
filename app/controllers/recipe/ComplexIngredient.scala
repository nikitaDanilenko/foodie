package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import services.{ComplexFoodId, RecipeId}
import utils.TransformerUtils.Implicits._

import java.util.UUID

@JsonCodec
case class ComplexIngredient(
    complexFoodId: UUID,
    factor: BigDecimal
)

object ComplexIngredient {

  implicit val fromInternal: Transformer[services.complex.ingredient.ComplexIngredient, ComplexIngredient] =
    Transformer
      .define[services.complex.ingredient.ComplexIngredient, ComplexIngredient]
      .buildTransformer

  implicit val toInternal: Transformer[(ComplexIngredient, UUID), services.complex.ingredient.ComplexIngredient] = {
    case (complexIngredient, recipeId) =>
      services.complex.ingredient.ComplexIngredient(
        recipeId = recipeId.transformInto[RecipeId],
        complexFoodId = complexIngredient.complexFoodId.transformInto[ComplexFoodId],
        factor = complexIngredient.factor
      )
  }

}
