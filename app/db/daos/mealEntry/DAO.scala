package db.daos.mealEntry

import db.daos.meal.MealKey
import db.generated.Tables
import db.{ DAOActions, MealId, ProfileId, UserId }
import io.scalaland.chimney.syntax._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID
import scala.concurrent.ExecutionContext

trait DAO extends DAOActions[Tables.MealEntryRow, MealEntryKey] {

  override def keyOf: Tables.MealEntryRow => MealEntryKey = MealEntryKey.of

  def findAllFor(
      userId: UserId,
      profileId: ProfileId,
      mealIds: Seq[MealId]
  )(implicit
      ec: ExecutionContext
  ): DBIO[Map[MealKey, Seq[Tables.MealEntryRow]]]

}

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.MealEntryRow, Tables.MealEntry, MealEntryKey](
      Tables.MealEntry,
      (table, key) =>
        table.userId === key.userId.transformInto[UUID] &&
          table.profileId === key.profileId.transformInto[UUID] &&
          table.mealId === key.mealId.transformInto[UUID] &&
          table.id === key.id.transformInto[UUID]
    ) with DAO {

      override def findAllFor(
          userId: UserId,
          profileId: ProfileId,
          mealIds: Seq[MealId]
      )(implicit ec: ExecutionContext): DBIO[Map[MealKey, Seq[Tables.MealEntryRow]]] = {
        val untypedIds = mealIds.distinct.map(_.transformInto[UUID])
        Tables.MealEntry
          .filter(meal =>
            meal.userId === userId.transformInto[UUID] &&
              meal.profileId === profileId.transformInto[UUID] &&
              meal.mealId.inSetBind(untypedIds)
          )
          .result
          .map { mealEntries =>
            mealEntries
              .groupBy(_.mealId)
              .map { case (mealId, entries) => MealKey(userId, profileId, mealId.transformInto[MealId]) -> entries }
          }
      }

    }

}
