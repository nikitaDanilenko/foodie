package controllers.meal

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

import java.util.UUID

@JsonCodec
case class MealEntryCreation(
    mealId: UUID,
    recipeId: UUID,
    numberOfServings: BigDecimal
)

object MealEntryCreation {

  implicit val toInternal: Transformer[MealEntryCreation, services.meal.MealEntryCreation] =
    Transformer
      .define[MealEntryCreation, services.meal.MealEntryCreation]
      .buildTransformer

}
