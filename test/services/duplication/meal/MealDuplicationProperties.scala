package services.duplication.meal

import cats.data.{ EitherT, NonEmptyList }
import cats.instances.future._
import db._
import db.daos.meal.MealKey
import errors.ServerError
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Gen, Prop, Properties }
import services.common.RequestInterval
import services.meal.{ FullMeal, Meal, MealEntry, MealService }
import services.recipe.Recipe
import services.{ ContentsUtil, DBTestUtil, GenUtils, TestUtil }
import util.DateUtil
import utils.date.SimpleDate

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object MealDuplicationProperties extends Properties("Meal duplication") {

  case class Services(
      mealService: MealService,
      duplication: Duplication
  )

  def servicesWith(
      userId: UserId,
      profileId: ProfileId,
      fullMeal: FullMeal
  ): Services = {
    val mealDao      = DAOTestInstance.Meal.instanceFrom(ContentsUtil.Meal.from(userId, profileId, Seq(fullMeal.meal)))
    val mealEntryDao = DAOTestInstance.MealEntry.instanceFrom(ContentsUtil.MealEntry.from(userId, profileId, fullMeal))

    val mealServiceCompanion = new services.meal.Live.Companion(
      mealDao = mealDao,
      mealEntryDao = mealEntryDao
    )

    Services(
      mealService = new services.meal.Live(
        TestUtil.databaseConfigProvider,
        mealServiceCompanion
      ),
      duplication = new services.duplication.meal.Live(
        TestUtil.databaseConfigProvider,
        new services.duplication.meal.Live.Companion(
          mealServiceCompanion,
          mealEntryDao
        ),
        mealServiceCompanion = mealServiceCompanion
      )
    )
  }

  private case class DuplicationSetup(
      userId: UserId,
      profileId: ProfileId,
      recipes: List[Recipe],
      fullMeal: FullMeal
  )

  private val duplicationSetupGen: Gen[DuplicationSetup] = for {
    userId    <- GenUtils.taggedId[UserTag]
    profileId <- GenUtils.taggedId[ProfileTag]
    recipes   <- Gen.nonEmptyListOf(services.recipe.Gens.recipeGen)
    fullMeal  <- services.meal.Gens.fullMealGen(NonEmptyList.fromListUnsafe(recipes.map(_.id)))
  } yield DuplicationSetup(
    userId = userId,
    profileId = profileId,
    recipes = recipes,
    fullMeal = fullMeal
  )

  private case class MealEntryValues(
      recipeId: RecipeId,
      numberOfServings: BigDecimal
  )

  private def groupMealEntries(mealEntries: Seq[MealEntry]): Map[RecipeId, List[MealEntryValues]] =
    mealEntries
      .groupBy(_.recipeId)
      .view
      .mapValues(
        _.sortBy(_.numberOfServings)
          .map(mealEntry => MealEntryValues(mealEntry.recipeId, mealEntry.numberOfServings))
          .toList
      )
      .toMap

  property("Duplication produces expected result") = Prop.forAll(duplicationSetupGen :| "setup") { setup =>
    val services = servicesWith(
      userId = setup.userId,
      profileId = setup.profileId,
      fullMeal = setup.fullMeal
    )
    val transformer = for {
      timestamp <- EitherT.liftF[Future, ServerError, SimpleDate](DateUtil.now)
      duplicatedMeal <- EitherT(
        services.duplication.duplicate(setup.userId, setup.profileId, setup.fullMeal.meal.id, timestamp)
      )
      mealEntries <- EitherT
        .liftF[Future, ServerError, Map[MealKey, Seq[MealEntry]]](
          services.mealService.getMealEntries(setup.userId, setup.profileId, Seq(duplicatedMeal.id))
        )
        .map(_.getOrElse(MealKey(setup.userId, setup.profileId, duplicatedMeal.id), List.empty))
    } yield {
      Prop.all(
        groupMealEntries(mealEntries) ?= groupMealEntries(setup.fullMeal.mealEntries),
        duplicatedMeal.name.exists { name =>
          setup.fullMeal.meal.name.fold(name.startsWith("(copy"))(name.startsWith)
        }
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Duplication adds value") = Prop.forAll(duplicationSetupGen :| "setup") { setup =>
    val services = servicesWith(
      userId = setup.userId,
      profileId = setup.profileId,
      fullMeal = setup.fullMeal
    )
    val transformer = for {
      allMealsBefore <- EitherT.liftF[Future, ServerError, Seq[Meal]](
        services.mealService.allMeals(setup.userId, setup.profileId, RequestInterval(None, None))
      )
      timestamp <- EitherT.liftF[Future, ServerError, SimpleDate](DateUtil.now)
      duplicated <- EitherT(
        services.duplication.duplicate(setup.userId, setup.profileId, setup.fullMeal.meal.id, timestamp)
      )
      allMealsAfter <- EitherT.liftF[Future, ServerError, Seq[Meal]](
        services.mealService.allMeals(setup.userId, setup.profileId, RequestInterval(None, None))
      )
    } yield {
      allMealsAfter.map(_.id).sorted ?= (allMealsBefore :+ duplicated).map(_.id).sorted
    }

    DBTestUtil.awaitProp(transformer)
  }

  // Todo: Add tests for other mismatches
  property("Duplication fails for wrong user id") = Prop.forAll(
    duplicationSetupGen :| "setup",
    GenUtils.taggedId[UserTag] :| "userId2"
  ) { (setup, userId2) =>
    val services = servicesWith(
      userId = setup.userId,
      profileId = setup.profileId,
      fullMeal = setup.fullMeal
    )
    val propF = for {
      timestamp <- DateUtil.now
      result    <- services.duplication.duplicate(userId2, setup.profileId, setup.fullMeal.meal.id, timestamp)
    } yield result.isLeft

    DBTestUtil.await(propF)
  }
}
