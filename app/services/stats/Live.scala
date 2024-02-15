package services.stats

import algebra.ring.AdditiveMonoid
import cats.data.{ EitherT, OptionT }
import cats.syntax.contravariantSemigroupal._
import cats.syntax.traverse._
import db._
import db.daos.meal.MealKey
import db.generated.Tables
import io.scalaland.chimney.dsl.TransformerOps
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.DBError
import services.common.RequestInterval
import services.common.Transactionally.syntax._
import services.complex.food.ComplexFoodService
import services.complex.ingredient.{ ComplexIngredient, ComplexIngredientService, ScalingMode }
import services.meal.{ MealEntry, MealService }
import services.nutrient.NutrientService.ConversionFactorKey
import services.nutrient.{ AmountEvaluation, Nutrient, NutrientMap, NutrientService }
import services.recipe.{ Recipe, RecipeService }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import spire.compat._
import spire.implicits._
import spire.math.Natural
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._
import utils.collection.MapUtil

import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }
import scala.util.chaining._

class Live @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider,
    companion: StatsService.Companion
)(implicit
    ec: ExecutionContext
) extends StatsService
    with HasDatabaseConfigProvider[PostgresProfile] {

  override def nutrientsOverTime(
      userId: UserId,
      profileId: ProfileId,
      requestInterval: RequestInterval
  ): Future[Stats] =
    db.runTransactionally(companion.nutrientsOverTime(userId, profileId, requestInterval))

  override def nutrientsOfFood(foodId: FoodId): Future[Option[NutrientAmountMap]] =
    db.runTransactionally(companion.nutrientsOfFood(foodId))

  override def nutrientsOfComplexFood(
      userId: UserId,
      complexFoodId: ComplexFoodId
  ): Future[Option[NutrientAmountMap]] =
    db.runTransactionally(companion.nutrientsOfComplexFood(userId, complexFoodId))

  override def nutrientsOfRecipe(userId: UserId, recipeId: RecipeId): Future[Option[NutrientAmountMap]] =
    db.runTransactionally(companion.nutrientsOfRecipe(userId, recipeId))

  override def nutrientsOfMeal(userId: UserId, profileId: ProfileId, mealId: MealId): Future[NutrientAmountMap] =
    db.runTransactionally(companion.nutrientsOfMeal(userId, profileId, mealId))

  override def weightOfRecipe(userId: UserId, recipeId: RecipeId): Future[Option[BigDecimal]] =
    db.runTransactionally(companion.weightOfRecipe(userId, recipeId))

  override def weightOfMeal(userId: UserId, profileId: ProfileId, mealId: MealId): Future[Option[BigDecimal]] =
    db.runTransactionally(companion.weightOfMeal(userId, profileId, mealId))

  override def weightOfMeals(userId: UserId, profileId: ProfileId, mealIds: Seq[MealId]): Future[Option[BigDecimal]] =
    db.runTransactionally(companion.weightOfMeals(userId, profileId, mealIds))

  override def recipeOccurrences(userId: UserId, profileId: ProfileId): Future[Seq[RecipeOccurrence]] =
    db.runTransactionally(companion.recipeOccurrences(userId, profileId))

}

object Live {

  class Companion @Inject() (
      mealService: MealService.Companion,
      recipeService: RecipeService.Companion,
      nutrientService: NutrientService.Companion,
      complexFoodService: ComplexFoodService.Companion,
      complexIngredientService: ComplexIngredientService.Companion
  ) extends StatsService.Companion {

    override def nutrientsOverTime(
        userId: UserId,
        profileId: ProfileId,
        requestInterval: RequestInterval
    )(implicit
        ec: ExecutionContext
    ): DBIO[Stats] = {
      for {
        meals <- mealService.allMeals(userId, profileId, requestInterval)
        mealIds = meals.map(_.id)
        meals              <- mealService.getMeals(userId, profileId, mealIds)
        mealEntries        <- mealService.getMealEntries(userId, profileId, mealIds).map(_.values.flatten.toSeq)
        nutrientsPerRecipe <- nutrientsOfRecipeIds(userId, mealEntries.map(_.recipeId))
        allNutrients       <- nutrientService.all
      } yield {
        val nutrientAmountMap =
          nutrientAmountMapOfMealEntries(mealEntries, nutrientsPerRecipe, allNutrients)
        Stats(
          meals = meals,
          nutrientAmountMap = nutrientAmountMap
        )
      }
    }

    override def nutrientsOfFood(foodId: FoodId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[NutrientAmountMap]] = {
      val transformer = for {
        _ <- OptionT(
          Tables.FoodName
            .filter(_.foodId === foodId.transformInto[Int])
            .result
            .headOption: DBIO[Option[Tables.FoodNameRow]]
        )
        nutrientMap  <- OptionT.liftF(nutrientService.nutrientsOfFood(foodId, None, BigDecimal(1)))
        allNutrients <- OptionT.liftF(nutrientService.all)
      } yield unifyAndCount(
        nutrientMap = nutrientMap,
        totalNumberOfIngredients = 1,
        allNutrients = allNutrients
      )

      transformer.value
    }

    override def nutrientsOfComplexFood(userId: UserId, complexFoodId: ComplexFoodId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[NutrientAmountMap]] = {
      val transformer = for {
        complexFood <- OptionT(complexFoodService.get(userId, complexFoodId))
        recipeStats <- OptionT(nutrientsOfRecipeWith(userId, complexFoodId, ScaleMode.Unit(complexFood.amountGrams)))
      } yield recipeStats

      transformer.value
    }

    override def nutrientsOfRecipe(
        userId: UserId,
        recipeId: RecipeId
    )(implicit
        ec: ExecutionContext
    ): DBIO[Option[NutrientAmountMap]] =
      nutrientsOfRecipeWith(userId, recipeId, ScaleMode.Serving)

    private def nutrientsOfRecipeWith(
        userId: UserId,
        recipeId: RecipeId,
        scaleMode: ScaleMode
    )(implicit
        ec: ExecutionContext
    ): DBIO[Option[NutrientAmountMap]] = {
      val transformer = for {
        allNutrients <- OptionT.liftF(nutrientService.all)
        recipeNutrientMap <- OptionT(
          nutrientsOfRecipes(
            userId = userId,
            recipeIds = Seq(recipeId),
            scaleMode = scaleMode
          )
            .map(_.headOption): DBIO[Option[RecipeNutrientMap]]
        )
      } yield unifyAndCount(
        recipeNutrientMap.nutrientMap,
        totalNumberOfIngredients = recipeNutrientMap.foodIds.size,
        allNutrients = allNutrients
      )

      transformer.value
    }

    override def nutrientsOfMeal(
        userId: UserId,
        profileId: ProfileId,
        mealId: MealId
    )(implicit
        ec: ExecutionContext
    ): DBIO[NutrientAmountMap] =
      for {
        mealEntries        <- mealService.getMealEntries(userId, profileId, Seq(mealId)).map(_.values.flatten.toSeq)
        nutrientsPerRecipe <- nutrientsOfRecipeIds(userId, mealEntries.map(_.recipeId))
        allNutrients       <- nutrientService.all
      } yield nutrientAmountMapOfMealEntries(mealEntries, nutrientsPerRecipe, allNutrients)

    override def weightOfRecipe(userId: UserId, recipeId: RecipeId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[BigDecimal]] =
      OptionT(weightsOfRecipes(userId, Seq(recipeId)))
        .subflatMap(_.get(recipeId))
        .value

    override def weightOfMeal(userId: UserId, profileId: ProfileId, mealId: MealId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[BigDecimal]] = weightOfMeals(userId, profileId, Seq(mealId))

    override def weightOfMeals(userId: UserId, profileId: ProfileId, mealIds: Seq[MealId])(implicit
        ec: ExecutionContext
    ): DBIO[Option[BigDecimal]] =
      for {
        mealEntries <- mealService.getMealEntries(userId, profileId, mealIds)
        weights     <- weightsOfMealEntries(userId, mealEntries.values.flatten.toSeq)
      } yield weights

    override def recipeOccurrences(userId: UserId, profileId: ProfileId)(implicit
        ec: ExecutionContext
    ): DBIO[Seq[RecipeOccurrence]] = {
      for {
        allMeals       <- mealService.allMeals(userId, profileId, RequestInterval(None, None))
        allMealEntries <- mealService.getMealEntries(userId, profileId, allMeals.map(_.id))
        allRecipes     <- recipeService.allRecipes(userId)
      } yield {
        val mealMap   = allMeals.map(meal => MealKey(userId, profileId, meal.id) -> meal).toMap
        val recipeMap = allRecipes.map(recipe => recipe.id -> recipe).toMap
        val inSomeMeal = allMealEntries.toList
          .flatMap { case (mealId, mealEntries) =>
            mealEntries.map(mealId -> _)
          }
          .groupBy(_._2.recipeId)
          .map { case (recipeId, mealEntries) =>
            val latestMeal = mealEntries.map(_._1.pipe(mealMap)).maxBy(_.date)
            recipeId -> RecipeOccurrence(
              recipe = recipeMap(recipeId),
              lastUsedInMeal = Some(latestMeal)
            )
          }
        val inNoMeal = recipeMap.view.mapValues(RecipeOccurrence(_, None)).toMap
        MapUtil
          .unionWith(
            inNoMeal,
            inSomeMeal
          )((_, x) => x)
          .values
          .toSeq
      }
    }

    private def weightsOfMealEntries(
        userId: UserId,
        mealEntries: Seq[MealEntry]
    )(implicit
        ec: ExecutionContext
    ): DBIO[Option[BigDecimal]] = {
      val recipeIds = mealEntries.map(_.recipeId)
      val transformer = for {
        recipes <- OptionT.liftF(recipeService.getRecipes(userId, recipeIds))
        recipeMap = recipes.map(recipe => recipe.id -> recipe).toMap
        recipeWeights <- OptionT(weightsOfRecipes(userId, recipeIds))
        weights <- OptionT.fromOption {
          // Traverse without asynchronous effect
          mealEntries.toList.traverse { mealEntry =>
            for {
              recipeWeight <- recipeWeights.get(mealEntry.recipeId)
              recipe       <- recipeMap.get(mealEntry.recipeId)
            } yield mealEntry.numberOfServings * recipeWeight / recipe.numberOfServings
          }
        }
      } yield weights.sum

      transformer.value
    }

    private def weightsOfRecipes(userId: UserId, recipeIds: Seq[RecipeId])(implicit
        ec: ExecutionContext
    ): DBIO[Option[Map[RecipeId, BigDecimal]]] = {
      for {
        ingredientsMap        <- recipeService.getAllIngredients(userId, recipeIds)
        complexIngredientsMap <- complexIngredientService.all(userId, recipeIds)
        conversionFactorMap <- nutrientService.conversionFactors(
          ingredientsMap.values.flatten.map(ConversionFactorKey.of).toSeq
        )
        complexIngredients = complexIngredientsMap.values.flatten.toSeq
        complexFoods <- complexFoodService.getAll(userId, complexIngredients.map(_.complexFoodId))
      } yield {
        val complexFoodsMap = complexFoods.map(complexFood => complexFood.recipeId -> complexFood).toMap
        val ingredientWeights =
          ingredientsMap.toList
            .traverse { case (recipeId, ingredients) =>
              ingredients
                .traverse { ingredient =>
                  conversionFactorMap
                    .get(ConversionFactorKey.of(ingredient))
                    .map(100 * ingredient.amountUnit.factor * _)
                }
                .map(weights => recipeId -> weights.sum)
            }
            .map(_.toMap)
        val complexIngredientsWeights = complexIngredientsMap.toList
          .traverse { case (recipeId, complexIngredients) =>
            complexIngredients.toList
              .traverse { complexIngredient =>
                complexFoodsMap
                  .get(complexIngredient.complexFoodId)
                  .flatMap { complexFood =>
                    val scalingFactor = complexIngredient.scalingMode match {
                      case ScalingMode.Recipe => Some(BigDecimal(1))
                      case ScalingMode.Weight => Some(BigDecimal(100) / complexFood.amountGrams)
                      case ScalingMode.Volume => complexFood.amountMilliLitres.map(BigDecimal(100) / _)
                    }
                    scalingFactor.map { factor =>
                      complexIngredient.factor * factor * complexFood.amountGrams
                    }
                  }
              }
              .map(weights => recipeId -> weights.sum)
          }
          .map(_.toMap)
        (ingredientWeights, complexIngredientsWeights).mapN(MapUtil.unionWith(_, _)(_ + _))
      }
    }

    private def nutrientsOfRecipeIds(
        userId: UserId,
        recipeIds: Seq[RecipeId]
    )(implicit ec: ExecutionContext): DBIO[Map[RecipeId, RecipeNutrientMap]] =
      nutrientsOfRecipes(userId, recipeIds.distinct, ScaleMode.Serving)
        .map(_.map(recipeNutrientMap => recipeNutrientMap.recipe.id -> recipeNutrientMap).toMap)

    private def nutrientsOfRecipes(
        userId: UserId,
        recipeIds: Seq[RecipeId],
        scaleMode: ScaleMode
    )(implicit
        ec: ExecutionContext
    ): DBIO[Seq[RecipeNutrientMap]] = {
      case class NutrientsAndFoods(
          nutrientMap: NutrientMap,
          foodIds: Set[FoodId]
      )

      def nutrientsOfComplexIngredient(complexIngredient: ComplexIngredient): DBIO[NutrientsAndFoods] =
        for {
          rescaleFactor <- complexIngredient.scalingMode match {
            case ScalingMode.Recipe => DBIO.successful(BigDecimal(1))
            case ScalingMode.Weight =>
              OptionT(complexFoodService.get(userId, complexIngredient.complexFoodId))
                .map(complexFood => BigDecimal(100) / complexFood.amountGrams)
                .getOrElseF(DBIO.failed(DBError.Complex.Food.NotFound))
            case ScalingMode.Volume =>
              val transformer = for {
                complexFood <- EitherT.fromOptionF(
                  complexFoodService.get(userId, complexIngredient.complexFoodId),
                  DBError.Complex.Food.NotFound: DBError
                )
                volume <- EitherT.fromOption(
                  complexFood.amountMilliLitres,
                  DBError.Complex.Food.MissingVolume: DBError
                )
              } yield BigDecimal(100) / volume

              transformer.valueOrF(DBIO.failed)
          }
          recipeNutrientMap <- descend(complexIngredient.complexFoodId)
        } yield recipeNutrientMap.copy(nutrientMap =
          complexIngredient.factor *: rescaleFactor *: recipeNutrientMap.nutrientMap
        )

      def descend(recipeId: RecipeId): DBIO[NutrientsAndFoods] =
        for {
          ingredients        <- recipeService.getIngredients(userId, recipeId)
          complexIngredients <- complexIngredientService.all(userId, Seq(recipeId))
          nutrients          <- nutrientService.nutrientsOfIngredients(ingredients)
          recipeNutrientMapsOfComplexNutrients <- complexIngredients.values.flatten.toList
            .traverse(nutrientsOfComplexIngredient)
        } yield NutrientsAndFoods(
          nutrientMap = nutrients + recipeNutrientMapsOfComplexNutrients.map(_.nutrientMap).qsum,
          foodIds = ingredients.map(_.foodId).toSet ++ recipeNutrientMapsOfComplexNutrients.flatMap(_.foodIds)
        )

      for {
        recipes <- recipeService.getRecipes(userId, recipeIds)
        allNutrientsAndFoods <- recipes.traverse { recipe =>
          descend(recipe.id).map(recipe -> _): DBIO[(Recipe, NutrientsAndFoods)]
        }
      } yield allNutrientsAndFoods.map { case (recipe, nutrientsAndFoods) =>
        val scale = scaleMode match {
          case ScaleMode.Serving             => recipe.numberOfServings.reciprocal
          case ScaleMode.Unit(definedAmount) => BigDecimal(100) / definedAmount
        }
        RecipeNutrientMap(
          recipe = recipe,
          nutrientMap = scale *: nutrientsAndFoods.nutrientMap,
          foodIds = nutrientsAndFoods.foodIds
        )
      }
    }

    private sealed trait ScaleMode

    private object ScaleMode {
      case object Serving extends ScaleMode

      case class Unit(definedAmount: BigDecimal) extends ScaleMode
    }

    private def nutrientAmountMapOfMealEntries(
        mealEntries: Seq[MealEntry],
        nutrientsPerRecipe: Map[RecipeId, RecipeNutrientMap],
        allNutrients: Seq[Nutrient]
    ): NutrientAmountMap = {
      val nutrientMap = mealEntries.map { mealEntry =>
        mealEntry.numberOfServings *: nutrientsPerRecipe(mealEntry.recipeId).nutrientMap
      }.qsum
      val totalNumberOfIngredients = nutrientsPerRecipe.values.flatMap(_.foodIds).toSet.size

      unifyAndCount(
        nutrientMap = nutrientMap,
        totalNumberOfIngredients = totalNumberOfIngredients,
        allNutrients = allNutrients
      )
    }

    private def unifyAndCount(
        nutrientMap: NutrientMap,
        totalNumberOfIngredients: Int,
        allNutrients: Seq[Nutrient]
    ): NutrientAmountMap = {
      MapUtil
        .unionWith(
          nutrientMap,
          allNutrients.map(n => n -> AdditiveMonoid[AmountEvaluation].zero).toMap
        )((x, _) => x)
        .view
        .mapValues(amountEvaluation =>
          Amount(
            value = Some(amountEvaluation.amount).filter(_ => amountEvaluation.encounteredFoodIds.nonEmpty),
            numberOfIngredients = Natural(totalNumberOfIngredients),
            numberOfDefinedValues = Natural(amountEvaluation.encounteredFoodIds.size)
          )
        )
        .toMap
    }

  }

}
