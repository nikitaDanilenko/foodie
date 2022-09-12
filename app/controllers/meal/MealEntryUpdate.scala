package controllers.meal

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

import java.util.UUID

@JsonCodec
case class MealEntryUpdate(
    mealEntryId: UUID,
    recipeId: UUID,
    numberOfServings: BigDecimal
)

object MealEntryUpdate {

  implicit val toInternal: Transformer[MealEntryUpdate, services.meal.MealEntryUpdate] = {
    Transformer
      .define[MealEntryUpdate, services.meal.MealEntryUpdate]
      .withFieldRenamed(_.mealEntryId, _.id)
      .buildTransformer
  }

}
