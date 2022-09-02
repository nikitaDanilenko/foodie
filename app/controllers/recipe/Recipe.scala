package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

import java.util.UUID

@JsonCodec
case class Recipe(
    id: UUID,
    name: String,
    description: Option[String]
)

object Recipe {

  implicit val fromInternal: Transformer[services.recipe.Recipe, Recipe] =
    Transformer
      .define[services.recipe.Recipe, Recipe]
      .buildTransformer

}
