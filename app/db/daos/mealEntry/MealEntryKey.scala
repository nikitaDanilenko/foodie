package db.daos.mealEntry

import db.generated.Tables
import db.{ MealEntryId, MealId, ProfileId, UserId }
import io.scalaland.chimney.syntax._
import utils.TransformerUtils.Implicits._

case class MealEntryKey(
    userId: UserId,
    profileId: ProfileId,
    mealId: MealId,
    id: MealEntryId
)

object MealEntryKey {

  def of(row: Tables.MealEntryRow): MealEntryKey =
    MealEntryKey(
      row.userId.transformInto[UserId],
      row.profileId.transformInto[ProfileId],
      row.mealId.transformInto[MealId],
      row.id.transformInto[MealEntryId]
    )

}
