package services.stats

import cats.data.NonEmptyList
import db.{ ProfileId, ProfileTag, UserId, UserTag }
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Gen, Prop, Properties }
import services.meal.FullMeal
import services.recipe.Recipe
import services._
import spire.compat._
import spire.math.Natural

import scala.concurrent.ExecutionContext.Implicits.global

object RecipeOccurrenceProperties extends Properties("Recipe occurrence") {

  private case class UserIdAndRecipes(
      userId: UserId,
      recipes: NonEmptyList[Recipe]
  )

  private val maxNumberOfRecipesPerMeal = Natural(10)

  private val userIdAndRecipesGen = for {
    userId  <- GenUtils.taggedId[UserTag]
    recipes <- GenUtils.nonEmptyListOfAtMost(maxNumberOfRecipesPerMeal, recipe.Gens.recipeGen)
  } yield UserIdAndRecipes(
    userId = userId,
    recipes = recipes
  )

  private case class MealsSetup(
      userAndRecipes: UserIdAndRecipes,
      profileId: ProfileId,
      fullMeals: List[FullMeal]
  )

  private val mealsSetupGen: Gen[MealsSetup] =
    for {
      userAndRecipe <- userIdAndRecipesGen
      profileId     <- GenUtils.taggedId[ProfileTag]
      fullMeals     <- Gen.nonEmptyListOf(meal.Gens.fullMealGen(userAndRecipe.recipes.map(_.id)))
    } yield MealsSetup(
      userAndRecipes = userAndRecipe,
      profileId = profileId,
      fullMeals = fullMeals
    )

  property("Latest") = Prop.forAll(
    mealsSetupGen :| "setup"
  ) { setup =>
    val userId    = setup.userAndRecipes.userId
    val recipeMap = setup.userAndRecipes.recipes.map(recipe => recipe.id -> recipe).toList.toMap
    val statsService = ServiceFunctions.statsServiceWith(
      mealContents = ContentsUtil.Meal.from(userId, setup.profileId, setup.fullMeals.map(_.meal)),
      mealEntryContents = setup.fullMeals.flatMap(ContentsUtil.MealEntry.from(userId, setup.profileId, _)),
      recipeContents = ContentsUtil.Recipe.from(userId, setup.userAndRecipes.recipes.toList),
      ingredientContents = Seq.empty
    )

    val propF = for {
      recipeOccurrencesFromService <- statsService.recipeOccurrences(userId, setup.profileId)
    } yield {
      val latestProps = recipeOccurrencesFromService.map { recipeOccurrence =>
        val expected =
          RecipeOccurrence(
            recipeMap(recipeOccurrence.recipe.id),
            setup.fullMeals
              .collect {
                case fullMeal if fullMeal.mealEntries.exists(_.recipeId == recipeOccurrence.recipe.id) =>
                  fullMeal.meal
              }
              .maxByOption(_.date)
          )
        recipeOccurrence ?= expected
      }

      Prop.all(
        ((recipeOccurrencesFromService.map(_.recipe).sortBy(_.id) ?= recipeMap.values.toSeq.sortBy(_.id))
          +: latestProps): _*
      )
    }

    DBTestUtil.await(propF)
  }

}
