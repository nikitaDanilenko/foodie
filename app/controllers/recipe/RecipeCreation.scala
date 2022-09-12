package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class RecipeCreation(
    name: String,
    description: Option[String],
    numberOfServings: BigDecimal
)

object RecipeCreation {

  implicit val toInternal: Transformer[RecipeCreation, services.recipe.RecipeCreation] =
    Transformer
      .define[RecipeCreation, services.recipe.RecipeCreation]
      .buildTransformer

}
