package services.meal

import db.generated.Tables
import db.{ MealEntryId, MealId, ProfileId, RecipeId, UserId }
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class MealEntry(
    id: MealEntryId,
    recipeId: RecipeId,
    numberOfServings: BigDecimal
)

object MealEntry {

  implicit val fromDB: Transformer[Tables.MealEntryRow, MealEntry] =
    Transformer
      .define[Tables.MealEntryRow, MealEntry]
      .buildTransformer

  case class TransformableToDB(
      userId: UserId,
      profileId: ProfileId,
      mealId: MealId,
      mealEntry: MealEntry
  )

  implicit val toDB: Transformer[TransformableToDB, Tables.MealEntryRow] = { transformableToDB =>
    Tables.MealEntryRow(
      id = transformableToDB.mealEntry.id.transformInto[UUID],
      mealId = transformableToDB.mealId.transformInto[UUID],
      recipeId = transformableToDB.mealEntry.recipeId.transformInto[UUID],
      numberOfServings = transformableToDB.mealEntry.numberOfServings,
      userId = transformableToDB.userId.transformInto[UUID],
      profileId = transformableToDB.profileId.transformInto[UUID]
    )
  }

}
