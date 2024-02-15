package db.daos.meal

import db.generated.Tables
import db.{ MealId, ProfileId, UserId }
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._

case class MealKey(
    userId: UserId,
    profileId: ProfileId,
    mealId: MealId
)

object MealKey {

  def of(row: Tables.MealRow): MealKey =
    MealKey(
      row.userId.transformInto[UserId],
      row.profileId.transformInto[ProfileId],
      row.id.transformInto[MealId]
    )

}
