package services.duplication.reference

import cats.data.EitherT
import db.{ DAOTestInstance, UserId }
import errors.ServerError
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Gen, Prop, Properties }
import services.reference.{ FullReferenceMap, ReferenceEntry, ReferenceMap, ReferenceService }
import services.{ ContentsUtil, DBTestUtil, GenUtils, TestUtil }
import util.DateUtil

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object ReferenceMapDuplicationProperties extends Properties("Reference map duplication") {

  case class Services(
      referenceService: ReferenceService,
      duplication: Duplication
  )

  def servicesWith(
      userId: UserId,
      fullReferenceMap: FullReferenceMap
  ): Services = {
    val referenceMapDao = DAOTestInstance.ReferenceMap.instanceFrom(
      ContentsUtil.ReferenceMap.from(userId, Seq(fullReferenceMap.referenceMap))
    )
    val referenceEntryDao =
      DAOTestInstance.ReferenceMapEntry.instanceFrom(ContentsUtil.ReferenceEntry.from(userId, fullReferenceMap))

    val referenceServiceCompanion = new services.reference.Live.Companion(
      referenceMapDao = referenceMapDao,
      referenceMapEntryDao = referenceEntryDao,
      nutrientTableConstants = DBTestUtil.nutrientTableConstants
    )

    Services(
      referenceService = new services.reference.Live(
        TestUtil.databaseConfigProvider,
        referenceServiceCompanion
      ),
      duplication = new services.duplication.reference.Live(
        TestUtil.databaseConfigProvider,
        new services.duplication.reference.Live.Companion(
          referenceServiceCompanion,
          referenceEntryDao
        ),
        referenceServiceCompanion = referenceServiceCompanion
      )
    )
  }

  private case class DuplicationSetup(
      userId: UserId,
      fullReferenceMap: FullReferenceMap
  )

  private val duplicationSetupGen: Gen[DuplicationSetup] = for {
    userId           <- GenUtils.taggedId(UserId)
    fullReferenceMap <- services.reference.Gens.fullReferenceMapGen
  } yield DuplicationSetup(
    userId = userId,
    fullReferenceMap = fullReferenceMap
  )

  property("Duplication produces expected result") = Prop.forAll(duplicationSetupGen :| "setup") { setup =>
    val services = servicesWith(
      userId = setup.userId,
      fullReferenceMap = setup.fullReferenceMap
    )
    val transformer = for {
      timestamp              <- EitherT.liftF(DateUtil.now)
      duplicatedReferenceMap <- EitherT(
        services.duplication.duplicate(setup.userId, setup.fullReferenceMap.referenceMap.id, timestamp)
      )
      referenceEntries <- EitherT
        .liftF[Future, ServerError, List[ReferenceEntry]](
          services.referenceService.allReferenceEntries(setup.userId, duplicatedReferenceMap.id)
        )
    } yield {
      Prop.all(
        referenceEntries.sortBy(_.nutrientCode) ?= setup.fullReferenceMap.referenceEntries.sortBy(_.nutrientCode),
        duplicatedReferenceMap.name.startsWith(setup.fullReferenceMap.referenceMap.name)
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Duplication adds value") = Prop.forAll(duplicationSetupGen :| "setup") { setup =>
    val services = servicesWith(
      userId = setup.userId,
      fullReferenceMap = setup.fullReferenceMap
    )
    val transformer = for {
      allReferenceMapsBefore <- EitherT.liftF[Future, ServerError, Seq[ReferenceMap]](
        services.referenceService.allReferenceMaps(setup.userId)
      )
      timestamp  <- EitherT.liftF(DateUtil.now)
      duplicated <- EitherT(
        services.duplication.duplicate(setup.userId, setup.fullReferenceMap.referenceMap.id, timestamp)
      )
      allReferenceMapsAfter <- EitherT.liftF[Future, ServerError, Seq[ReferenceMap]](
        services.referenceService.allReferenceMaps(setup.userId)
      )
    } yield {
      allReferenceMapsAfter.map(_.id).sorted ?= (allReferenceMapsBefore :+ duplicated).map(_.id).sorted
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Duplication fails for wrong user id") = Prop.forAll(
    duplicationSetupGen :| "setup",
    GenUtils.taggedId(UserId) :| "userId2"
  ) { (setup, userId2) =>
    val services = servicesWith(
      userId = setup.userId,
      fullReferenceMap = setup.fullReferenceMap
    )
    val propF = for {
      timestamp <- DateUtil.now
      result    <- services.duplication.duplicate(userId2, setup.fullReferenceMap.referenceMap.id, timestamp)
    } yield result.isLeft

    DBTestUtil.await(propF)
  }

}
