package services.reference

import cats.Applicative
import cats.data.OptionT
import cats.syntax.traverse._
import db.generated.Tables
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.nutrient.{ Nutrient, ReferenceNutrientMap }
import services.{ DBError, NutrientCode, ReferenceMapId, UserId }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

trait ReferenceService {
  def allReferenceMaps(userId: UserId): Future[Seq[ReferenceMap]]

  def getReferenceNutrientsMap(
      userId: UserId,
      referenceMapId: ReferenceMapId
  ): Future[Option[ReferenceNutrientMap]]

  def getReferenceMap(userId: UserId, referenceMapId: ReferenceMapId): Future[Option[ReferenceMap]]

  def allReferenceTrees(userId: UserId): Future[List[ReferenceTree]]

  def createReferenceMap(
      userId: UserId,
      referenceMapCreation: ReferenceMapCreation
  ): Future[ServerError.Or[ReferenceMap]]

  def updateReferenceMap(
      userId: UserId,
      referenceMapUpdate: ReferenceMapUpdate
  ): Future[ServerError.Or[ReferenceMap]]

  def delete(
      userId: UserId,
      referenceMapId: ReferenceMapId
  ): Future[Boolean]

  def allReferenceEntries(
      userId: UserId,
      referenceMapId: ReferenceMapId
  ): Future[List[ReferenceEntry]]

  def addReferenceEntry(
      userId: UserId,
      referenceEntryCreation: ReferenceEntryCreation
  ): Future[ServerError.Or[ReferenceEntry]]

  def updateReferenceEntry(
      userId: UserId,
      referenceEntryUpdate: ReferenceEntryUpdate
  ): Future[ServerError.Or[ReferenceEntry]]

  def deleteReferenceEntry(
      userId: UserId,
      referenceMapId: ReferenceMapId,
      nutrientCode: NutrientCode
  ): Future[Boolean]

}

object ReferenceService {

  class Live @Inject() (override protected val dbConfigProvider: DatabaseConfigProvider, companion: Companion)(implicit
      ec: ExecutionContext
  ) extends ReferenceService
      with HasDatabaseConfigProvider[PostgresProfile] {

    override def allReferenceMaps(userId: UserId): Future[Seq[ReferenceMap]] =
      db.run(companion.allReferenceMaps(userId))

    override def getReferenceNutrientsMap(
        userId: UserId,
        referenceMapId: ReferenceMapId
    ): Future[Option[ReferenceNutrientMap]] =
      db.run(companion.getReferenceNutrientsMap(userId, referenceMapId))

    override def getReferenceMap(userId: UserId, referenceMapId: ReferenceMapId): Future[Option[ReferenceMap]] =
      db.run(companion.getReferenceMap(userId, referenceMapId))

    override def allReferenceTrees(userId: UserId): Future[List[ReferenceTree]] = {
      val action = for {
        referenceMaps <- companion.allReferenceMaps(userId)
        referenceTrees <- referenceMaps.traverse(referenceMap =>
          OptionT(
            companion
              .getReferenceNutrientsMap(userId, referenceMap.id)
          )
            .map(ReferenceTree(referenceMap, _))
            .value
        )
      } yield referenceTrees.flatten.toList

      db.run(action.transactionally)
    }

    override def createReferenceMap(
        userId: UserId,
        referenceMapCreation: ReferenceMapCreation
    ): Future[ServerError.Or[ReferenceMap]] =
      db.run(
        companion.createReferenceMap(userId, UUID.randomUUID().transformInto[ReferenceMapId], referenceMapCreation)
      ).map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.ReferenceMap.Creation(error.getMessage).asServerError)
        }

    override def updateReferenceMap(
        userId: UserId,
        referenceMapUpdate: ReferenceMapUpdate
    ): Future[ServerError.Or[ReferenceMap]] =
      db.run(companion.updateReferenceMap(userId, referenceMapUpdate))
        .map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.ReferenceMap.Update(error.getMessage).asServerError)
        }

    override def delete(userId: UserId, referenceMapId: ReferenceMapId): Future[Boolean] =
      db.run(companion.delete(userId, referenceMapId))

    override def allReferenceEntries(userId: UserId, referenceMapId: ReferenceMapId): Future[List[ReferenceEntry]] =
      db.run(companion.allReferenceEntries(userId, referenceMapId))

    override def addReferenceEntry(
        userId: UserId,
        referenceEntryCreation: ReferenceEntryCreation
    ): Future[ServerError.Or[ReferenceEntry]] =
      db.run(companion.addReferenceEntry(userId, referenceEntryCreation))
        .map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.ReferenceMap.Entry.Creation(error.getMessage).asServerError)
        }

    override def updateReferenceEntry(
        userId: UserId,
        referenceEntryUpdate: ReferenceEntryUpdate
    ): Future[ServerError.Or[ReferenceEntry]] =
      db.run(companion.updateReferenceEntry(userId, referenceEntryUpdate))
        .map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.ReferenceMap.Entry.Update(error.getMessage).asServerError)
        }

    override def deleteReferenceEntry(
        userId: UserId,
        referenceMapId: ReferenceMapId,
        nutrientCode: NutrientCode
    ): Future[Boolean] =
      db.run(companion.deleteReferenceEntry(userId, referenceMapId, nutrientCode))

  }

  trait Companion {
    def allReferenceMaps(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[ReferenceMap]]

    def getReferenceNutrientsMap(
        userId: UserId,
        referenceMapId: ReferenceMapId
    )(implicit ec: ExecutionContext): DBIO[Option[ReferenceNutrientMap]]

    def getReferenceMap(userId: UserId, referenceMapId: ReferenceMapId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[ReferenceMap]]

    def createReferenceMap(
        userId: UserId,
        id: ReferenceMapId,
        referenceMapCreation: ReferenceMapCreation
    )(implicit ec: ExecutionContext): DBIO[ReferenceMap]

    def updateReferenceMap(
        userId: UserId,
        referenceMapUpdate: ReferenceMapUpdate
    )(implicit ec: ExecutionContext): DBIO[ReferenceMap]

    def delete(
        userId: UserId,
        referenceMapId: ReferenceMapId
    )(implicit ec: ExecutionContext): DBIO[Boolean]

    def allReferenceEntries(
        userId: UserId,
        referenceMapId: ReferenceMapId
    )(implicit ec: ExecutionContext): DBIO[List[ReferenceEntry]]

    def addReferenceEntry(
        userId: UserId,
        referenceEntryCreation: ReferenceEntryCreation
    )(implicit ec: ExecutionContext): DBIO[ReferenceEntry]

    def updateReferenceEntry(
        userId: UserId,
        referenceEntryUpdate: ReferenceEntryUpdate
    )(implicit ec: ExecutionContext): DBIO[ReferenceEntry]

    def deleteReferenceEntry(
        userId: UserId,
        referenceMapId: ReferenceMapId,
        nutrientCode: NutrientCode
    )(implicit ec: ExecutionContext): DBIO[Boolean]

  }

  object Live extends Companion {

    override def allReferenceMaps(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[ReferenceMap]] =
      Tables.ReferenceMap
        .filter(_.userId === userId.transformInto[UUID])
        .result
        .map(
          _.map(_.transformInto[ReferenceMap])
        )

    override def getReferenceNutrientsMap(
        userId: UserId,
        referenceMapId: ReferenceMapId
    )(implicit ec: ExecutionContext): DBIO[Option[ReferenceNutrientMap]] = {
      val transformer = for {
        referenceEntries <- OptionT.liftF(allReferenceEntries(userId, referenceMapId))
        referenceEntriesAmounts <-
          referenceEntries
            .traverse { referenceEntry =>
              OptionT(
                nutrientNameByCode(referenceEntry.nutrientCode)
              ).map(nutrientNameRow => nutrientNameRow.transformInto[Nutrient] -> referenceEntry.amount)
            }
      } yield referenceEntriesAmounts.toMap

      transformer.value
    }

    override def getReferenceMap(userId: UserId, referenceMapId: ReferenceMapId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[ReferenceMap]] =
      OptionT(referenceMapQuery(userId, referenceMapId).result.headOption: DBIO[Option[Tables.ReferenceMapRow]])
        .map(_.transformInto[ReferenceMap])
        .value

    override def createReferenceMap(
        userId: UserId,
        id: ReferenceMapId,
        referenceMapCreation: ReferenceMapCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[ReferenceMap] = {
      val referenceMap    = ReferenceMapCreation.create(id, referenceMapCreation)
      val referenceMapRow = (referenceMap, userId).transformInto[Tables.ReferenceMapRow]
      (Tables.ReferenceMap.returning(Tables.ReferenceMap) += referenceMapRow)
        .map(_.transformInto[ReferenceMap])
    }

    override def updateReferenceMap(userId: UserId, referenceMapUpdate: ReferenceMapUpdate)(implicit
        ec: ExecutionContext
    ): DBIO[ReferenceMap] = {
      val findAction =
        OptionT(getReferenceMap(userId, referenceMapUpdate.id)).getOrElseF(notFound)
      for {
        referenceMap <- findAction
        _ <- referenceMapQuery(userId, referenceMapUpdate.id).update(
          (
            ReferenceMapUpdate
              .update(referenceMap, referenceMapUpdate),
            userId
          )
            .transformInto[Tables.ReferenceMapRow]
        )
        updatedReferenceMap <- findAction
      } yield updatedReferenceMap
    }

    override def delete(userId: UserId, referenceMapId: ReferenceMapId)(implicit ec: ExecutionContext): DBIO[Boolean] =
      referenceMapQuery(userId, referenceMapId).delete
        .map(_ > 0)

    override def allReferenceEntries(userId: UserId, referenceMapId: ReferenceMapId)(implicit
        ec: ExecutionContext
    ): DBIO[List[ReferenceEntry]] =
      for {
        exists <- referenceMapQuery(userId, referenceMapId).exists.result
        referenceEntries <-
          if (exists)
            Tables.ReferenceEntry
              .filter(_.referenceMapId === referenceMapId.transformInto[UUID])
              .result
              .map(_.map(_.transformInto[ReferenceEntry]).toList)
          else Applicative[DBIO].pure(List.empty)
      } yield referenceEntries

    override def addReferenceEntry(
        userId: UserId,
        referenceEntryCreation: ReferenceEntryCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[ReferenceEntry] = {
      val referenceEntry = ReferenceEntryCreation.create(referenceEntryCreation)
      val referenceEntryRow =
        (referenceEntry, referenceEntryCreation.referenceMapId).transformInto[Tables.ReferenceEntryRow]
      val query = referenceEntryQuery(referenceEntryCreation.referenceMapId, referenceEntryCreation.nutrientCode)
      ifReferenceMapExists(userId, referenceEntryCreation.referenceMapId) {
        for {
          exists <- query.exists.result
          row <-
            if (exists)
              query
                .update(referenceEntryRow)
                .andThen(query.result.head)
            else
              Tables.ReferenceEntry.returning(Tables.ReferenceEntry) += referenceEntryRow
        } yield row.transformInto[ReferenceEntry]
      }
    }

    override def updateReferenceEntry(userId: UserId, referenceEntryUpdate: ReferenceEntryUpdate)(implicit
        ec: ExecutionContext
    ): DBIO[ReferenceEntry] = {
      val findAction =
        OptionT(
          referenceEntryQuery(
            referenceEntryUpdate.referenceMapId,
            referenceEntryUpdate.nutrientCode
          ).result.headOption: DBIO[
            Option[Tables.ReferenceEntryRow]
          ]
        )
          .getOrElseF(DBIO.failed(DBError.Reference.EntryNotFound))
      for {
        referenceEntryRow <- findAction
        _ <- referenceEntryQuery(referenceEntryUpdate.referenceMapId, referenceEntryUpdate.nutrientCode).update(
          (
            ReferenceEntryUpdate
              .update(referenceEntryRow.transformInto[ReferenceEntry], referenceEntryUpdate),
            referenceEntryRow.referenceMapId.transformInto[ReferenceMapId]
          )
            .transformInto[Tables.ReferenceEntryRow]
        )
        updatedReferenceEntryRow <- findAction
      } yield updatedReferenceEntryRow.transformInto[ReferenceEntry]
    }

    override def deleteReferenceEntry(userId: UserId, referenceMapId: ReferenceMapId, nutrientCode: NutrientCode)(
        implicit ec: ExecutionContext
    ): DBIO[Boolean] =
      ifReferenceMapExists(userId, referenceMapId) {
        referenceEntryQuery(referenceMapId, nutrientCode).delete
          .map(_ > 0)
      }

    private def referenceMapQuery(
        userId: UserId,
        id: ReferenceMapId
    ): Query[Tables.ReferenceMap, Tables.ReferenceMapRow, Seq] =
      Tables.ReferenceMap.filter(r =>
        r.id === id.transformInto[UUID] &&
          r.userId === userId.transformInto[UUID]
      )

    private def referenceEntryQuery(
        referenceMapId: ReferenceMapId,
        nutrientCode: NutrientCode
    ): Query[Tables.ReferenceEntry, Tables.ReferenceEntryRow, Seq] =
      Tables.ReferenceEntry
        .filter(r =>
          r.referenceMapId === referenceMapId.transformInto[UUID] &&
            r.nutrientCode === nutrientCode.transformInto[Int]
        )

    private def nutrientNameByCode(nutrientCode: Int): DBIO[Option[Tables.NutrientNameRow]] =
      Tables.NutrientName
        .filter(_.nutrientCode === nutrientCode)
        .result
        .headOption

    private def ifReferenceMapExists[A](
        userId: UserId,
        id: ReferenceMapId
    )(action: => DBIO[A])(implicit ec: ExecutionContext): DBIO[A] =
      referenceMapQuery(userId, id).exists.result.flatMap(exists => if (exists) action else notFound)

    private def notFound[A]: DBIO[A] = DBIO.failed(DBError.Reference.MapNotFound)
  }

}
