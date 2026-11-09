package services.reference

import cats.data.EitherT
import config.TestConfiguration
import db.{ UserId, _ }
import errors.{ ErrorContext, ServerError }
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Gen, Prop, Properties, Test }
import services.{ ContentsUtil, DBTestUtil, GenUtils, TestUtil }

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object ReferenceServiceProperties extends Properties("Reference service properties") {

  def companionWith(
      referenceMapContents: Seq[(UserId, ReferenceMap)],
      referenceMapEntryContents: Seq[(UserId, ReferenceMapId, ReferenceEntry)]
  ): services.reference.Live.Companion =
    new services.reference.Live.Companion(
      referenceMapDao = DAOTestInstance.ReferenceMap.instanceFrom(referenceMapContents),
      referenceMapEntryDao = DAOTestInstance.ReferenceMapEntry.instanceFrom(referenceMapEntryContents),
      nutrientTableConstants = DBTestUtil.nutrientTableConstants
    )

  def referenceMapServiceWith(
      referenceMapContents: Seq[(UserId, ReferenceMap)],
      referenceMapEntryContents: Seq[(UserId, ReferenceMapId, ReferenceEntry)]
  ): ReferenceService =
    new services.reference.Live(
      dbConfigProvider = TestUtil.databaseConfigProvider,
      companion = companionWith(
        referenceMapContents = referenceMapContents,
        referenceMapEntryContents = referenceMapEntryContents
      )
    )

  property("Creation") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId",
    Gens.referenceMapCreationGen :| "reference map"
  ) { (userId, referenceMapCreation) =>
    val referenceMapService = referenceMapServiceWith(
      referenceMapContents = Seq.empty,
      referenceMapEntryContents = Seq.empty
    )
    val transformer = for {
      createdReferenceMap <- EitherT(referenceMapService.createReferenceMap(userId, referenceMapCreation))
      fetchedReferenceMap <- EitherT.fromOptionF(
        referenceMapService.getReferenceMap(userId, createdReferenceMap.id),
        ErrorContext.ReferenceMap.NotFound.asServerError
      )
    } yield {
      val expectedReferenceMap = ReferenceMapCreation.create(createdReferenceMap.id, referenceMapCreation)
      Prop.all(
        createdReferenceMap ?= expectedReferenceMap,
        fetchedReferenceMap ?= expectedReferenceMap
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Read single") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId",
    Gens.referenceMapGen :| "reference map"
  ) { (userId, referenceMap) =>
    val referenceMapService = referenceMapServiceWith(
      referenceMapContents = ContentsUtil.ReferenceMap.from(userId, Seq(referenceMap)),
      referenceMapEntryContents = Seq.empty
    )
    val transformer = for {
      fetchedReferenceMap <- EitherT.fromOptionF(
        referenceMapService.getReferenceMap(userId, referenceMap.id),
        ErrorContext.ReferenceMap.NotFound.asServerError
      )
    } yield fetchedReferenceMap ?= referenceMap

    DBTestUtil.awaitProp(transformer)
  }

  property("Read all") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId",
    Gen.listOf(Gens.referenceMapGen) :| "reference maps"
  ) { (userId, referenceMaps) =>
    val referenceMapService = referenceMapServiceWith(
      referenceMapContents = ContentsUtil.ReferenceMap.from(userId, referenceMaps),
      referenceMapEntryContents = Seq.empty
    )
    val transformer = for {
      fetchedReferenceMaps <- EitherT.liftF[Future, ServerError, Seq[ReferenceMap]](
        referenceMapService.allReferenceMaps(userId)
      )
    } yield fetchedReferenceMaps.sortBy(_.id) ?= referenceMaps.sortBy(_.id)

    DBTestUtil.awaitProp(transformer)
  }

  private case class UpdateSetup(
      userId: UserId,
      referenceMap: ReferenceMap,
      referenceMapUpdate: ReferenceMapUpdate
  )

  private val updateSetupGen: Gen[UpdateSetup] =
    for {
      userId             <- GenUtils.taggedId(UserId)
      referenceMap       <- Gens.referenceMapGen
      referenceMapUpdate <- Gens.referenceMapUpdateGen
    } yield UpdateSetup(
      userId,
      referenceMap,
      referenceMapUpdate
    )

  property("Update") = Prop.forAll(
    updateSetupGen :| "update setup"
  ) { updateSetup =>
    val referenceMapService = referenceMapServiceWith(
      referenceMapContents = ContentsUtil.ReferenceMap.from(updateSetup.userId, Seq(updateSetup.referenceMap)),
      referenceMapEntryContents = Seq.empty
    )
    val transformer = for {
      updatedReferenceMap <-
        EitherT(
          referenceMapService.updateReferenceMap(
            updateSetup.userId,
            updateSetup.referenceMap.id,
            updateSetup.referenceMapUpdate
          )
        )
      fetchedReferenceMap <- EitherT.fromOptionF(
        referenceMapService.getReferenceMap(updateSetup.userId, updateSetup.referenceMap.id),
        ErrorContext.ReferenceMap.NotFound.asServerError
      )
    } yield {
      val expectedReferenceMap = ReferenceMapUpdate.update(updateSetup.referenceMap, updateSetup.referenceMapUpdate)
      Prop.all(
        updatedReferenceMap ?= expectedReferenceMap,
        fetchedReferenceMap ?= expectedReferenceMap
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Delete") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId",
    Gens.referenceMapGen :| "referenceMap"
  ) { (userId, referenceMap) =>
    val referenceMapService = referenceMapServiceWith(
      referenceMapContents = ContentsUtil.ReferenceMap.from(userId, Seq(referenceMap)),
      referenceMapEntryContents = Seq.empty
    )
    val transformer = for {
      result  <- EitherT.liftF[Future, ServerError, Boolean](referenceMapService.delete(userId, referenceMap.id))
      fetched <- EitherT.liftF[Future, ServerError, Option[ReferenceMap]](
        referenceMapService.getReferenceMap(userId, referenceMap.id)
      )
    } yield Prop.all(
      Prop(result) :| "Deletion successful",
      Prop(fetched.isEmpty) :| "Reference map should be deleted"
    )

    DBTestUtil.awaitProp(transformer)
  }

  private case class AddReferenceEntrySetup(
      fullReferenceMap: FullReferenceMap,
      referenceEntry: ReferenceEntry
  )

  private val addReferenceEntrySetupGen: Gen[AddReferenceEntrySetup] = for {
    fullReferenceMap <- Gens.fullReferenceMapGen
    referenceEntry   <- Gen.oneOf(fullReferenceMap.referenceEntries)
  } yield AddReferenceEntrySetup(
    fullReferenceMap.copy(
      referenceEntries = fullReferenceMap.referenceEntries.filter(_.nutrientCode != referenceEntry.nutrientCode)
    ),
    referenceEntry
  )

  property("Add reference entry") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId",
    addReferenceEntrySetupGen :| "setup"
  ) { (userId, setup) =>
    val referenceMapService = referenceMapServiceWith(
      referenceMapContents = ContentsUtil.ReferenceMap.from(userId, Seq(setup.fullReferenceMap.referenceMap)),
      referenceMapEntryContents = ContentsUtil.ReferenceEntry.from(userId, setup.fullReferenceMap)
    )
    val referenceMapEntryCreation =
      ReferenceEntryCreation(
        setup.referenceEntry.nutrientCode,
        setup.referenceEntry.amount
      )
    val transformer = for {
      referenceMapEntry <- EitherT(
        referenceMapService.addReferenceEntry(userId, setup.fullReferenceMap.referenceMap.id, referenceMapEntryCreation)
      )
      referenceMapEntries <- EitherT.liftF[Future, ServerError, List[ReferenceEntry]](
        referenceMapService.allReferenceEntries(userId, setup.fullReferenceMap.referenceMap.id)
      )
    } yield {
      val expectedReferenceEntry = ReferenceEntryCreation.create(referenceMapEntryCreation)
      Prop.all(
        referenceMapEntry ?= expectedReferenceEntry,
        referenceMapEntries.sortBy(
          _.nutrientCode
        ) ?= (expectedReferenceEntry +: setup.fullReferenceMap.referenceEntries)
          .sortBy(
            _.nutrientCode
          )
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Read reference entries") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId",
    Gens.fullReferenceMapGen :| "full reference map"
  ) { (userId, fullReferenceMap) =>
    val referenceMapService = referenceMapServiceWith(
      referenceMapContents = ContentsUtil.ReferenceMap.from(userId, Seq(fullReferenceMap.referenceMap)),
      referenceMapEntryContents = ContentsUtil.ReferenceEntry.from(userId, fullReferenceMap)
    )
    val transformer = for {
      referenceMapEntries <- EitherT.liftF[Future, ServerError, List[ReferenceEntry]](
        referenceMapService.allReferenceEntries(userId, fullReferenceMap.referenceMap.id)
      )
    } yield referenceMapEntries.sortBy(_.nutrientCode) ?= fullReferenceMap.referenceEntries.sortBy(_.nutrientCode)

    DBTestUtil.awaitProp(transformer)
  }

  private case class ReferenceEntryUpdateSetup(
      userId: UserId,
      fullReferenceMap: FullReferenceMap,
      referenceMapEntry: ReferenceEntry,
      referenceMapEntryUpdate: ReferenceEntryUpdate
  )

  private val referenceMapEntryUpdateSetupGen: Gen[ReferenceEntryUpdateSetup] =
    for {
      userId                  <- GenUtils.taggedId(UserId)
      fullReferenceMap        <- Gens.fullReferenceMapGen
      referenceMapEntry       <- Gen.oneOf(fullReferenceMap.referenceEntries)
      referenceMapEntryUpdate <- Gens.referenceEntryUpdateGen
    } yield ReferenceEntryUpdateSetup(
      userId = userId,
      fullReferenceMap = fullReferenceMap,
      referenceMapEntry = referenceMapEntry,
      referenceMapEntryUpdate = referenceMapEntryUpdate
    )

  property("Update reference entry") = Prop.forAll(
    referenceMapEntryUpdateSetupGen :| "setup"
  ) { setup =>
    val referenceMapService = referenceMapServiceWith(
      referenceMapContents = ContentsUtil.ReferenceMap.from(setup.userId, Seq(setup.fullReferenceMap.referenceMap)),
      referenceMapEntryContents = ContentsUtil.ReferenceEntry.from(setup.userId, setup.fullReferenceMap)
    )

    val transformer = for {
      updatedReferenceEntry <-
        EitherT(
          referenceMapService.updateReferenceEntry(
            setup.userId,
            setup.fullReferenceMap.referenceMap.id,
            setup.referenceMapEntry.nutrientCode,
            setup.referenceMapEntryUpdate
          )
        )
      referenceMapEntries <- EitherT.liftF[Future, ServerError, List[ReferenceEntry]](
        referenceMapService.allReferenceEntries(setup.userId, setup.fullReferenceMap.referenceMap.id)
      )
    } yield {
      val expectedReferenceEntry = ReferenceEntryUpdate.update(
        setup.referenceMapEntry,
        setup.referenceMapEntryUpdate
      )
      val expectedReferenceEntries =
        setup.fullReferenceMap.referenceEntries.map { referenceMapEntry =>
          if (referenceMapEntry.nutrientCode == setup.referenceMapEntry.nutrientCode) expectedReferenceEntry
          else referenceMapEntry
        }
      Prop.all(
        (updatedReferenceEntry ?= expectedReferenceEntry) :| "Update correct",
        (referenceMapEntries.sortBy(_.nutrientCode) ?= expectedReferenceEntries.sortBy(
          _.nutrientCode
        )) :| "Reference entries after update correct"
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  private case class DeleteReferenceEntrySetup(
      userId: UserId,
      fullReferenceMap: FullReferenceMap,
      nutrientCode: NutrientCode
  )

  private val deleteReferenceEntrySetupGen: Gen[DeleteReferenceEntrySetup] =
    for {
      userId           <- GenUtils.taggedId(UserId)
      fullReferenceMap <- Gens.fullReferenceMapGen
      nutrientCode     <- Gen.oneOf(fullReferenceMap.referenceEntries).map(_.nutrientCode)
    } yield DeleteReferenceEntrySetup(
      userId = userId,
      fullReferenceMap = fullReferenceMap,
      nutrientCode = nutrientCode
    )

  property("Delete reference entry") = Prop.forAll(
    deleteReferenceEntrySetupGen :| "setup"
  ) { setup =>
    val referenceMapService = referenceMapServiceWith(
      referenceMapContents = ContentsUtil.ReferenceMap.from(setup.userId, Seq(setup.fullReferenceMap.referenceMap)),
      referenceMapEntryContents = ContentsUtil.ReferenceEntry.from(setup.userId, setup.fullReferenceMap)
    )

    val transformer = for {
      deletionResult <- EitherT.liftF(
        referenceMapService.deleteReferenceEntry(
          setup.userId,
          setup.fullReferenceMap.referenceMap.id,
          setup.nutrientCode
        )
      )
      referenceMapEntries <- EitherT.liftF[Future, ServerError, List[ReferenceEntry]](
        referenceMapService.allReferenceEntries(setup.userId, setup.fullReferenceMap.referenceMap.id)
      )
    } yield {
      val expectedReferenceEntries =
        setup.fullReferenceMap.referenceEntries.filter(_.nutrientCode != setup.nutrientCode)
      Prop.all(
        Prop(deletionResult) :| "Deletion successful",
        (referenceMapEntries.sortBy(_.nutrientCode) ?= expectedReferenceEntries.sortBy(
          _.nutrientCode
        )) :| "Reference entries after update correct"
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Creation (wrong user)") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId1",
    GenUtils.taggedId(UserId) :| "userId2",
    Gens.referenceMapCreationGen :| "reference map creation"
  ) { case (userId1, userId2, referenceMapCreation) =>
    val referenceMapService = referenceMapServiceWith(
      referenceMapContents = Seq.empty,
      referenceMapEntryContents = Seq.empty
    )
    val transformer = for {
      createdReferenceMap <- EitherT(referenceMapService.createReferenceMap(userId1, referenceMapCreation))
      fetchedReferenceMap <- EitherT.liftF[Future, ServerError, Option[ReferenceMap]](
        referenceMapService.getReferenceMap(userId2, createdReferenceMap.id)
      )
    } yield Prop(fetchedReferenceMap.isEmpty) :| "Access denied"

    DBTestUtil.awaitProp(transformer)
  }

  property("Read single (wrong user)") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId1",
    GenUtils.taggedId(UserId) :| "userId2",
    Gens.referenceMapGen :| "reference map"
  ) { case (userId1, userId2, referenceMap) =>
    val referenceMapService = referenceMapServiceWith(
      referenceMapContents = ContentsUtil.ReferenceMap.from(userId1, Seq(referenceMap)),
      referenceMapEntryContents = Seq.empty
    )
    val transformer = for {
      fetchedReferenceMap <- EitherT.liftF[Future, ServerError, Option[ReferenceMap]](
        referenceMapService.getReferenceMap(userId2, referenceMap.id)
      )
    } yield Prop(fetchedReferenceMap.isEmpty) :| "Access denied"

    DBTestUtil.awaitProp(transformer)
  }

  property("Read all (wrong user)") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId1",
    GenUtils.taggedId(UserId) :| "userId2",
    Gen.listOf(Gens.referenceMapGen) :| "reference maps"
  ) { case (userId1, userId2, referenceMaps) =>
    val referenceMapService = referenceMapServiceWith(
      referenceMapContents = ContentsUtil.ReferenceMap.from(userId1, referenceMaps),
      referenceMapEntryContents = Seq.empty
    )
    val transformer = for {
      fetchedReferenceMaps <- EitherT.liftF[Future, ServerError, Seq[ReferenceMap]](
        referenceMapService.allReferenceMaps(userId2)
      )
    } yield fetchedReferenceMaps ?= Seq.empty

    DBTestUtil.awaitProp(transformer)
  }

  // TODO: Add tests for other mismatches
  property("Update (wrong user)") = Prop.forAll(
    updateSetupGen :| "setup",
    GenUtils.taggedId(UserId) :| "userId2"
  ) { (setup, userId2) =>
    val referenceMapService = referenceMapServiceWith(
      referenceMapContents = ContentsUtil.ReferenceMap.from(setup.userId, Seq(setup.referenceMap)),
      referenceMapEntryContents = Seq.empty
    )
    val transformer = for {
      updatedReferenceMap <- EitherT.liftF[Future, ServerError, ServerError.Or[ReferenceMap]](
        referenceMapService.updateReferenceMap(userId2, setup.referenceMap.id, setup.referenceMapUpdate)
      )
    } yield Prop(updatedReferenceMap.isLeft)

    DBTestUtil.awaitProp(transformer)
  }

  // TODO: Add tests for other mismatches
  property("Delete (wrong user)") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId1",
    GenUtils.taggedId(UserId) :| "userId2",
    Gens.referenceMapGen :| "reference map"
  ) { case (userId1, userId2, referenceMap) =>
    val referenceMapService = referenceMapServiceWith(
      referenceMapContents = ContentsUtil.ReferenceMap.from(userId1, Seq(referenceMap)),
      referenceMapEntryContents = Seq.empty
    )
    val transformer = for {
      result <- EitherT.liftF[Future, ServerError, Boolean](referenceMapService.delete(userId2, referenceMap.id))
    } yield Prop(!result) :| "Deletion failed"

    DBTestUtil.awaitProp(transformer)
  }

  // TODO: Add tests for other mismatches
  property("Add reference entry (wrong user)") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId1",
    GenUtils.taggedId(UserId) :| "userId2",
    Gens.fullReferenceMapGen :| "full reference map",
    Gens.referenceEntryGen :| "reference entry"
  ) { case (userId1, userId2, fullReferenceMap, referenceMapEntry) =>
    val referenceMapService = referenceMapServiceWith(
      referenceMapContents = ContentsUtil.ReferenceMap.from(userId1, Seq(fullReferenceMap.referenceMap)),
      referenceMapEntryContents = ContentsUtil.ReferenceEntry.from(userId1, fullReferenceMap)
    )
    val referenceMapEntryCreation =
      ReferenceEntryCreation(
        referenceMapEntry.nutrientCode,
        referenceMapEntry.amount
      )
    val transformer = for {
      result <- EitherT.liftF(
        referenceMapService.addReferenceEntry(userId2, fullReferenceMap.referenceMap.id, referenceMapEntryCreation)
      )
      referenceMapEntries <- EitherT.liftF[Future, ServerError, List[ReferenceEntry]](
        referenceMapService.allReferenceEntries(userId1, fullReferenceMap.referenceMap.id)
      )
    } yield Prop.all(
      Prop(result.isLeft) :| "Reference entry addition failed",
      referenceMapEntries.sortBy(_.nutrientCode) ?= fullReferenceMap.referenceEntries.sortBy(_.nutrientCode)
    )

    DBTestUtil.awaitProp(transformer)
  }

  // TODO: Add tests for other mismatches
  property("Read reference entries (wrong user)") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId1",
    GenUtils.taggedId(UserId) :| "userId2",
    Gens.fullReferenceMapGen :| "full reference map"
  ) { case (userId1, userId2, fullReferenceMap) =>
    val referenceMapService = referenceMapServiceWith(
      referenceMapContents = ContentsUtil.ReferenceMap.from(userId1, Seq(fullReferenceMap.referenceMap)),
      referenceMapEntryContents = ContentsUtil.ReferenceEntry.from(userId1, fullReferenceMap)
    )
    val transformer = for {
      referenceMapEntries <- EitherT.liftF[Future, ServerError, List[ReferenceEntry]](
        referenceMapService.allReferenceEntries(userId2, fullReferenceMap.referenceMap.id)
      )
    } yield referenceMapEntries.sortBy(_.nutrientCode) ?= List.empty

    DBTestUtil.awaitProp(transformer)
  }

  // TODO: Add tests for other mismatches
  property("Update reference entry (wrong user)") = Prop.forAll(
    referenceMapEntryUpdateSetupGen :| "reference entry update setup",
    GenUtils.taggedId(UserId) :| "userId2"
  ) { (setup, userId2) =>
    val referenceMapService = referenceMapServiceWith(
      referenceMapContents = ContentsUtil.ReferenceMap.from(setup.userId, Seq(setup.fullReferenceMap.referenceMap)),
      referenceMapEntryContents = ContentsUtil.ReferenceEntry.from(setup.userId, setup.fullReferenceMap)
    )
    val transformer = for {
      result <- EitherT.liftF(
        referenceMapService.updateReferenceEntry(
          userId2,
          setup.fullReferenceMap.referenceMap.id,
          setup.referenceMapEntry.nutrientCode,
          setup.referenceMapEntryUpdate
        )
      )
      referenceMapEntries <- EitherT.liftF[Future, ServerError, List[ReferenceEntry]](
        referenceMapService.allReferenceEntries(setup.userId, setup.fullReferenceMap.referenceMap.id)
      )
    } yield Prop.all(
      Prop(result.isLeft) :| "Reference entry update failed",
      (referenceMapEntries.sortBy(_.nutrientCode) ?= setup.fullReferenceMap.referenceEntries.sortBy(
        _.nutrientCode
      )) :| "Reference entries after update correct"
    )

    DBTestUtil.awaitProp(transformer)
  }

  // TODO: Add tests for other mismatches
  property("Delete reference entry (wrong user)") = Prop.forAll(
    deleteReferenceEntrySetupGen :| "wrong delete reference entry setup",
    GenUtils.taggedId(UserId) :| "userId2"
  ) { (setup, userId2) =>
    val referenceMapService = referenceMapServiceWith(
      referenceMapContents = ContentsUtil.ReferenceMap.from(setup.userId, Seq(setup.fullReferenceMap.referenceMap)),
      referenceMapEntryContents = ContentsUtil.ReferenceEntry.from(setup.userId, setup.fullReferenceMap)
    )
    val transformer = for {
      deletionResult <- EitherT.liftF(
        referenceMapService.deleteReferenceEntry(userId2, setup.fullReferenceMap.referenceMap.id, setup.nutrientCode)
      )
      referenceMapEntries <- EitherT.liftF[Future, ServerError, List[ReferenceEntry]](
        referenceMapService.allReferenceEntries(setup.userId, setup.fullReferenceMap.referenceMap.id)
      )
    } yield {
      val expectedReferenceEntries = setup.fullReferenceMap.referenceEntries
      Prop.all(
        Prop(!deletionResult) :| "Reference entry deletion failed",
        (referenceMapEntries.sortBy(_.nutrientCode) ?= expectedReferenceEntries.sortBy(
          _.nutrientCode
        )) :| "Reference entries after update correct"
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  override def overrideParameters(p: Test.Parameters): Test.Parameters =
    p.withMinSuccessfulTests(TestConfiguration.default.property.minSuccessfulTests.withoutDB)

}
