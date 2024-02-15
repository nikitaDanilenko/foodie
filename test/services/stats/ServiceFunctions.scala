package services.stats

import cats.data.OptionT
import cats.syntax.traverse._
import db._
import db.generated.Tables
import io.scalaland.chimney.dsl._
import services.complex.food.ComplexFoodServiceProperties
import services.complex.ingredient.ComplexIngredientServiceProperties
import services.meal.{ Meal, MealEntry }
import services.nutrient.NutrientService
import services.recipe._
import services.{ DBTestUtil, GenUtils, TestUtil }
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object ServiceFunctions {

  private val nutrientServiceCompanion = TestUtil.injector.instanceOf[NutrientService.Companion]

  // TODO #64: Add values for complex food, and complex ingredient services.
  def statsServiceWith(
      mealContents: Seq[(UserId, ProfileId, Meal)],
      mealEntryContents: Seq[(UserId, ProfileId, MealId, MealEntry)],
      recipeContents: Seq[(UserId, Recipe)],
      ingredientContents: Seq[(UserId, RecipeId, Ingredient)]
  ): StatsService = {
    new services.stats.Live(
      dbConfigProvider = TestUtil.databaseConfigProvider,
      companion = new services.stats.Live.Companion(
        mealService = new services.meal.Live.Companion(
          mealDao = DAOTestInstance.Meal.instanceFrom(mealContents),
          mealEntryDao = DAOTestInstance.MealEntry.instanceFrom(mealEntryContents)
        ),
        recipeService = new services.recipe.Live.Companion(
          recipeDao = DAOTestInstance.Recipe.instanceFrom(recipeContents),
          ingredientDao = DAOTestInstance.Ingredient.instanceFrom(ingredientContents),
          generalTableConstants = DBTestUtil.generalTableConstants
        ),
        nutrientService = nutrientServiceCompanion,
        complexFoodService = ComplexFoodServiceProperties.companionWith(
          recipeContents = recipeContents,
          // TODO #64: Use provided complex food values.
          complexFoodContents = Seq.empty,
          complexIngredientContents = Seq.empty
        ),
        complexIngredientService = ComplexIngredientServiceProperties.companionWith(
          recipeContents = recipeContents,
          // TODO #64: Use provided complex food values.
          complexFoodContents = Seq.empty,
          // TODO #64: Use provided complex ingredient values.
          complexIngredientContents = Seq.empty
        )
      )
    )
  }

  def computeNutrientAmount(
      nutrientId: NutrientId,
      ingredients: Seq[Ingredient]
  ): DBIO[Option[(Int, BigDecimal)]] = {
    val transformer =
      for {
        conversionFactors <-
          ingredients
            .traverse { ingredient =>
              OptionT
                .fromOption[DBIO](ingredient.amountUnit.measureId)
                .subflatMap(measureId => GenUtils.allConversionFactors.get((ingredient.foodId, measureId)))
                .orElseF(DBIO.successful(Some(BigDecimal(1))))
                .map(ingredient.id -> _)
            }
            .map(_.toMap)
        nutrientAmounts <- OptionT.liftF(nutrientAmountOf(nutrientId, ingredients.map(_.foodId)))
        ingredientAmounts = ingredients.flatMap { ingredient =>
          nutrientAmounts.get(ingredient.foodId).map { nutrientAmount =>
            nutrientAmount *
              ingredient.amountUnit.factor *
              conversionFactors(ingredient.id)
          }
        }
        amounts <- OptionT.fromOption[DBIO](Some(ingredientAmounts).filter(_.nonEmpty))
      } yield (nutrientAmounts.keySet.size, amounts.sum)

    transformer.value
  }

  def nutrientAmountOf(
      nutrientId: NutrientId,
      foodIds: Seq[FoodId]
  ): DBIO[Map[FoodId, BigDecimal]] = {
    val baseMap = Tables.NutrientAmount
      .filter(na =>
        na.nutrientId === nutrientId.transformInto[Int]
          && na.foodId.inSetBind(foodIds.map(_.transformInto[Int]))
      )
      .result
      .map { nutrientAmounts =>
        nutrientAmounts
          .map(na => na.foodId.transformInto[FoodId] -> na.nutrientValue)
          .toMap
      }
    /* The constellation of foodId = 534 and nutrientId = 339 has no entry in the
       amount table, but there is an entry referencing the non-existing nutrientId = 328,
       with the value 0.1.
       There is no nutrient with id 328, but there is one nutrient with the *code* 328,
       and this nutrient has the id 339.
       The assumption is that this reference has been added by mistake,
       hence we correct this mistake here.
     */
    val erroneousNutrientId = 339.transformInto[NutrientId]
    val erroneousFoodId     = 534.transformInto[FoodId]
    if (nutrientId == erroneousNutrientId && foodIds.contains(erroneousFoodId)) {
      baseMap.map(_.updated(erroneousFoodId, BigDecimal(0.1)))
    } else {
      baseMap
    }
  }

  def computeNutrientAmounts(
      fullRecipe: FullRecipe
  ): Future[Map[NutrientId, Option[(Int, BigDecimal)]]] = {
    DBTestUtil.dbRun {
      GenUtils.allNutrients
        .traverse { nutrient =>
          computeNutrientAmount(nutrient.id, fullRecipe.ingredients)
            .map(v =>
              nutrient.id ->
                v.map { case (number, value) => number -> value / fullRecipe.recipe.numberOfServings }
            ): DBIO[(NutrientId, Option[(Int, BigDecimal)])]
        }
        .map(_.toMap)
    }
  }

}
