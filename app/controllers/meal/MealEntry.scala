package controllers.meal

import java.util.UUID

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class MealEntry(
    id: UUID,
    recipeId: UUID,
    numberOfServings: BigDecimal
)

object MealEntry {

  implicit val fromInternal: Transformer[services.meal.MealEntry, MealEntry] =
    Transformer
      .define[services.meal.MealEntry, MealEntry]
      .buildTransformer

}
