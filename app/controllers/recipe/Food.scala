package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

import utils.TransformerUtils.Implicits._

@JsonCodec
case class Food(
    id: Int,
    name: String,
    measures: List[Measure]
)

object Food {

  implicit val fromInternal: Transformer[services.recipe.Food, Food] =
    Transformer
      .define[services.recipe.Food, Food]
      .buildTransformer

}
