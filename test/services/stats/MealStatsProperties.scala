package services.stats

import algebra.ring.AdditiveSemigroup
import cats.data.{ EitherT, NonEmptyList }
import cats.instances.list._
import cats.syntax.traverse._
import config.TestConfiguration
import db._
import errors.ServerError
import io.scalaland.chimney.dsl.TransformerOps
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Gen, Prop, Properties, Test }
import services._
import services.common.RequestInterval
import services.meal._
import services.recipe.FullRecipe
import spire.compat._
import spire.implicits._
import spire.math.interval._
import spire.math.{ Interval, Natural }
import util.{ DateUtil, PropUtil }
import utils.collection.MapUtil
import utils.date.Date

import java.time.LocalDate
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object MealStatsProperties extends Properties("Meal stats") {

  private case class SetupUserIdAndRecipes(
      userId: UserId,
      fullRecipes: NonEmptyList[FullRecipe]
  )

  private val maxNumberOfRecipesPerMeal = Natural(10)

  private val setupUserIdAndRecipesGen = for {
    userId      <- GenUtils.taggedId[UserTag]
    fullRecipes <- GenUtils.nonEmptyListOfAtMost(maxNumberOfRecipesPerMeal, recipe.Gens.fullRecipeGen())
  } yield SetupUserIdAndRecipes(
    userId = userId,
    fullRecipes = fullRecipes
  )

  private def computeNutrientsPerMealEntry(fullRecipes: Map[RecipeId, FullRecipe])(
      mealEntry: MealEntry
  ) = {
    services.stats.ServiceFunctions
      .computeNutrientAmounts(fullRecipes(mealEntry.recipeId))
      .map(
        _.view
          .mapValues(
            _.map {
              // TODO: Comparing the numbers of existing and non-existing values
              //       is not directly possible in the current implementation
              //       but would improve the test quality.
              //       However, it may be tricky to find a good implementation
              //       that is sufficiently different from the one already used
              //       in the production code.
              case (_, value) => value * mealEntry.numberOfServings
            }
          )
          .toMap
      )
  }

  private case class PerMealSetup(
      userAndRecipes: SetupUserIdAndRecipes,
      profileId: ProfileId,
      fullMeal: FullMeal
  )

  private val perMealSetupGen: Gen[PerMealSetup] =
    for {
      userAndRecipeSetup <- setupUserIdAndRecipesGen
      profileId          <- GenUtils.taggedId[ProfileTag]
      fullMeal           <- meal.Gens.fullMealGen(userAndRecipeSetup.fullRecipes.map(_.recipe.id))
    } yield PerMealSetup(
      userAndRecipes = userAndRecipeSetup,
      profileId = profileId,
      fullMeal = fullMeal
    )

  property("Per meal stats") = Prop.forAll(
    perMealSetupGen :| "Per meal setup"
  ) { setup =>
    val recipeMap = setup.userAndRecipes.fullRecipes.map(fr => fr.recipe.id -> fr).toList.toMap
    val statsService = ServiceFunctions.statsServiceWith(
      mealContents = ContentsUtil.Meal.from(setup.userAndRecipes.userId, setup.profileId, Seq(setup.fullMeal.meal)),
      mealEntryContents = ContentsUtil.MealEntry.from(setup.userAndRecipes.userId, setup.profileId, setup.fullMeal),
      recipeContents =
        ContentsUtil.Recipe.from(setup.userAndRecipes.userId, setup.userAndRecipes.fullRecipes.toList.map(_.recipe)),
      ingredientContents =
        setup.userAndRecipes.fullRecipes.toList.flatMap(ContentsUtil.Ingredient.from(setup.userAndRecipes.userId, _))
    )

    val transformer = for {
      expectedNutrientValues <- EitherT.liftF[Future, ServerError, Map[NutrientId, Option[BigDecimal]]](
        setup.fullMeal.mealEntries
          .traverse(computeNutrientsPerMealEntry(recipeMap))
          .map(
            _.foldLeft(Map.empty[NutrientId, Option[BigDecimal]])(
              MapUtil.unionWith(_, _)(AdditiveSemigroup[Option[BigDecimal]].plus)
            )
          )
      )
      nutrientMapFromService <- EitherT.liftF[Future, ServerError, NutrientAmountMap](
        statsService.nutrientsOfMeal(setup.userAndRecipes.userId, setup.profileId, setup.fullMeal.meal.id)
      )
    } yield {
      val propsPerNutrient = GenUtils.allNutrients.map { nutrient =>
        val prop = PropUtil.closeEnough(
          nutrientMapFromService.get(nutrient).flatMap(_.value),
          expectedNutrientValues.get(nutrient.id).flatten
        )
        prop :| s"Correct values for nutrientId = ${nutrient.id}"
      }

      Prop.all(
        propsPerNutrient: _*
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  private case class OverTimeSetup(
      userIdAndRecipes: SetupUserIdAndRecipes,
      profileId: ProfileId,
      dateInterval: Interval[Date],
      fullMeals: List[FullMeal]
  )

  private def dateIntervalGen(earliest: Int, latest: Int): Gen[Interval[Date]] = {
    val smallerDateGen = Gen.option(GenUtils.dateGen(earliest, latest))
    for {
      date1 <- smallerDateGen
      date2 <- smallerDateGen
    } yield DateUtil.toInterval(date1, date2)
  }

  private def overTimeSetupGen(
      range: Natural = Natural(1000)
  ): Gen[OverTimeSetup] = {
    val latest   = range.intValue
    val earliest = -latest

    for {
      dateInterval       <- dateIntervalGen(earliest, latest)
      userAndRecipeSetup <- setupUserIdAndRecipesGen
      profileId          <- GenUtils.taggedId[ProfileTag]
      fullMeals <-
        Gen.nonEmptyListOf(meal.Gens.fullMealGen(userAndRecipeSetup.fullRecipes.map(_.recipe.id), earliest, latest))
    } yield OverTimeSetup(
      userIdAndRecipes = userAndRecipeSetup,
      profileId = profileId,
      dateInterval = dateInterval,
      fullMeals = fullMeals
    )
  }

  property("Over time stats") = Prop.forAll(
    overTimeSetupGen() :| "Over time setup"
  ) { setup =>
    val userId = setup.userIdAndRecipes.userId
    val statsService = ServiceFunctions.statsServiceWith(
      mealContents = ContentsUtil.Meal.from(userId, setup.profileId, setup.fullMeals.map(_.meal)),
      mealEntryContents = setup.fullMeals.flatMap(ContentsUtil.MealEntry.from(userId, setup.profileId, _)),
      recipeContents = ContentsUtil.Recipe.from(userId, setup.userIdAndRecipes.fullRecipes.toList.map(_.recipe)),
      ingredientContents = setup.userIdAndRecipes.fullRecipes.toList.flatMap(ContentsUtil.Ingredient.from(userId, _))
    )

    val mealsInInterval =
      setup.fullMeals
        .filter(fullMeal => setup.dateInterval.contains(fullMeal.meal.date.date))
    val fullRecipeMap = setup.userIdAndRecipes.fullRecipes.map(fr => fr.recipe.id -> fr).toList.toMap

    val transformer = for {
      expectedNutrientValues <- EitherT.liftF[Future, ServerError, Map[NutrientId, Option[BigDecimal]]](
        mealsInInterval
          .flatMap(_.mealEntries)
          .traverse(computeNutrientsPerMealEntry(fullRecipeMap))
          .map(
            _.foldLeft(Map.empty[NutrientId, Option[BigDecimal]])(
              MapUtil.unionWith(_, _)(AdditiveSemigroup[Option[BigDecimal]].plus)
            )
          )
      )
      statsFromService <- EitherT.liftF[Future, ServerError, Stats](
        statsService.nutrientsOverTime(
          setup.userIdAndRecipes.userId,
          setup.profileId,
          toRequestInterval(setup.dateInterval)
        )
      )
    } yield {
      val mealsProp: Prop =
        compareMealAndParametersInOrder(statsFromService.meals, mealsInInterval) :| "Correct meals"

      val propsPerNutrient = GenUtils.allNutrients.map { nutrient =>
        val prop = PropUtil.closeEnough(
          statsFromService.nutrientAmountMap.get(nutrient).flatMap(_.value),
          expectedNutrientValues.get(nutrient.id).flatten
        )
        prop :| s"Correct values for nutrientId = ${nutrient.id}"
      }

      Prop.all(
        mealsProp +:
          propsPerNutrient: _*
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  private case class RestrictedOverTimeSetup(
      userId1: UserId,
      profileId1: ProfileId,
      userId2: UserId,
      profileId2: ProfileId,
      meals1: List[Meal],
      meals2: List[Meal],
      dateInterval: Interval[Date]
  )

  private val restrictedOverTimeSetupGen: Gen[RestrictedOverTimeSetup] =
    for {
      userId1      <- GenUtils.taggedId[UserTag]
      profileId1   <- GenUtils.taggedId[ProfileTag]
      userId2      <- GenUtils.taggedId[UserTag]
      profileId2   <- GenUtils.taggedId[ProfileTag]
      meals1       <- Gen.nonEmptyListOf(Gens.mealGen())
      meals2       <- Gen.nonEmptyListOf(Gens.mealGen())
      dateInterval <- dateIntervalGen(-10000, 10000)
    } yield RestrictedOverTimeSetup(
      userId1 = userId1,
      profileId1 = profileId1,
      userId2 = userId2,
      profileId2 = profileId2,
      meals1 = meals1,
      meals2 = meals2,
      dateInterval = dateInterval
    )

  // Regression test for a bug, where the meals were computed over all users.
  property("Meal stats restricted to user") = Prop.forAll(
    restrictedOverTimeSetupGen :| "restricted over time setup"
  ) { setup =>
    val statsService = ServiceFunctions.statsServiceWith(
      mealContents = ContentsUtil.Meal.from(setup.userId1, setup.profileId1, setup.meals1) ++
        ContentsUtil.Meal.from(setup.userId2, setup.profileId2, setup.meals2),
      mealEntryContents = Seq.empty,
      recipeContents = Seq.empty,
      ingredientContents = Seq.empty
    )
    val mealsInInterval =
      setup.meals1
        .filter(meal => setup.dateInterval.contains(meal.date.date))
    val transformer =
      for {
        statsFromService <- EitherT.liftF[Future, ServerError, Stats](
          statsService.nutrientsOverTime(
            setup.userId1,
            setup.profileId1,
            toRequestInterval(setup.dateInterval)
          )
        )
      } yield compareMealAndParametersInOrder(
        statsFromService.meals,
        mealsInInterval.map(FullMeal(_, List.empty))
      )

    DBTestUtil.awaitProp(transformer)
  }

  private def extractValue[A](bound: Bound[A]): Option[A] =
    bound match {
      case EmptyBound() => None
      case Unbound()    => None
      case Closed(x)    => Some(x)
      case Open(x)      => Some(x)
    }

  private def toRequestInterval(interval: Interval[Date]): RequestInterval = {
    def toLocalDate(bound: Bound[Date]) = extractValue(bound).map(_.transformInto[LocalDate])
    RequestInterval(
      from = toLocalDate(interval.lowerBound),
      to = toLocalDate(interval.upperBound)
    )
  }

  private def compareMealAndParametersInOrder(
      meals: Seq[Meal],
      fullMeals: Seq[FullMeal]
  ): Prop = {
    val lengthProp =
      (meals.length ?= fullMeals.length) :| "Correct number of meals"
    // TODO: This is a simplified assumption.
    //       It is possible for multiple meals to have the same date, and name, but contain different entries.
    //       The test could be extended by also comparing the recipe ids and amounts of the entries,
    //       which would lead to a sufficient equality in the sense that all comparable components are equal.
    //       In the current setting meal creations do not have uniquely identifying properties.
    val expectedDatesAndNames =
      fullMeals
        .map(fullMeal => (fullMeal.meal.date, fullMeal.meal.name))
        .sorted

    val actualDatesAndNames =
      meals
        .map(meal => (meal.date, meal.name))
        .sorted

    Prop.all(
      lengthProp,
      actualDatesAndNames ?= expectedDatesAndNames
    )
  }

  override def overrideParameters(p: Test.Parameters): Test.Parameters =
    p.withMinSuccessfulTests(TestConfiguration.default.property.minSuccessfulTests.withDB)

}
