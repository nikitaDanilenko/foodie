package services.rescale

import cats.data.EitherT
import cats.syntax.contravariantSemigroupal._
import cats.syntax.traverse._
import db.{ DAOTestInstance, UserId }
import errors.ErrorContext
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Arbitrary, Gen, Prop, Properties }
import services.GenUtils.implicits._
import services.complex.food.Gens.VolumeAmountOption
import services.complex.food.{ ComplexFood, ComplexFoodServiceProperties }
import services.complex.ingredient.{ ComplexIngredient, ComplexIngredientService }
import services.nutrient.NutrientService
import services.recipe.{ FullRecipe, Ingredient, Recipe, RecipeService }
import services.stats.StatsService
import services.{ ContentsUtil, DBTestUtil, GenUtils, TestUtil }
import util.PropUtil

import scala.concurrent.ExecutionContext.Implicits.global

object RescaleProperties extends Properties("Rescale properties") {

  private val nutrientServiceCompanion = TestUtil.injector.instanceOf[NutrientService.Companion]

  case class Services(
      recipeService: RecipeService,
      complexIngredientService: ComplexIngredientService,
      rescaleService: RescaleService,
      statsService: StatsService
  )

  def servicesWith(
      userId: UserId,
      complexFoods: List[ComplexFood],
      recipe: Recipe,
      referencedRecipes: List[Recipe],
      ingredients: List[Ingredient],
      complexIngredients: List[ComplexIngredient]
  ): Services = {
    val recipeDao = DAOTestInstance.Recipe.instanceFrom(ContentsUtil.Recipe.from(userId, recipe +: referencedRecipes))
    val complexFoodDao = DAOTestInstance.ComplexFood.instanceFrom(ContentsUtil.ComplexFood.from(userId, complexFoods))
    val ingredientDao  = DAOTestInstance.Ingredient.instanceFrom(
      ContentsUtil.Ingredient.from(
        userId,
        FullRecipe(
          recipe = recipe,
          ingredients = ingredients
        )
      )
    )
    val complexIngredientDao = DAOTestInstance.ComplexIngredient.instanceFrom(
      ContentsUtil.ComplexIngredient.from(userId, recipe.id, complexIngredients)
    )

    val recipeServiceCompanion = new services.recipe.Live.Companion(
      recipeDao = recipeDao,
      ingredientDao = ingredientDao,
      generalTableConstants = DBTestUtil.generalTableConstants
    )
    val complexIngredientServiceCompanion = new services.complex.ingredient.Live.Companion(
      recipeDao = recipeDao,
      complexFoodDao = complexFoodDao,
      complexIngredientDao = complexIngredientDao
    )

    val statsServiceCompanion = new services.stats.Live.Companion(
      mealService = new services.meal.Live.Companion(
        mealDao = DAOTestInstance.Meal.instanceFrom(Seq.empty),
        mealEntryDao = DAOTestInstance.MealEntry.instanceFrom(Seq.empty)
      ),
      recipeService = recipeServiceCompanion,
      nutrientService = nutrientServiceCompanion,
      complexFoodService = ComplexFoodServiceProperties.companionWith(
        recipeContents = ContentsUtil.Recipe.from(userId, referencedRecipes),
        complexFoodContents = ContentsUtil.ComplexFood.from(userId, complexFoods),
        complexIngredientContents = Seq.empty
      ),
      complexIngredientService = complexIngredientServiceCompanion
    )

    Services(
      recipeService = new services.recipe.Live(
        TestUtil.databaseConfigProvider,
        recipeServiceCompanion
      ),
      complexIngredientService = new services.complex.ingredient.Live(
        TestUtil.databaseConfigProvider,
        complexIngredientServiceCompanion
      ),
      rescaleService = new services.rescale.Live(
        TestUtil.databaseConfigProvider,
        new services.rescale.Live.Companion(
          recipeServiceCompanion,
          statsServiceCompanion
        )
      ),
      statsService = new services.stats.Live(
        TestUtil.databaseConfigProvider,
        statsServiceCompanion
      )
    )
  }

  private case class RescaleSetup(
      userId: UserId,
      recipe: Recipe,
      referencedRecipes: List[Recipe],
      complexFoods: List[ComplexFood],
      ingredients: List[Ingredient],
      complexIngredients: List[ComplexIngredient],
      servingSizeInGrams: BigDecimal
  )

  private val rescaleSetupGen: Gen[RescaleSetup] = for {
    userId                <- GenUtils.taggedId(UserId)
    recipe                <- services.recipe.Gens.recipeGen
    referencedRecipes     <- Gen.nonEmptyListOf(services.recipe.Gens.recipeGen)
    subsetForComplexFoods <- GenUtils.subset(referencedRecipes)
    complexFoods          <- subsetForComplexFoods.traverse(
      services.complex.food.Gens.complexFood(_, VolumeAmountOption.OptionalVolume)
    )
    ingredients        <- Gen.listOf(services.recipe.Gens.ingredientGen)
    complexIngredients <- services.complex.ingredient.Gens.complexIngredientsGen(complexFoods)
    servingSize        <- GenUtils.smallBigDecimalGen
    spaces             <- Gen.choose(0, 10)
  } yield RescaleSetup(
    userId = userId,
    recipe = recipe.copy(
      servingSize = Some(s"$servingSize${List.fill(spaces)(" ").mkString}g")
    ),
    referencedRecipes = referencedRecipes,
    complexFoods,
    ingredients = ingredients,
    complexIngredients = complexIngredients,
    servingSizeInGrams = servingSize
  )

  property("Rescaling produces expected result") = Prop.forAll(rescaleSetupGen :| "setup") { setup =>
    val services = servicesWith(
      userId = setup.userId,
      complexFoods = setup.complexFoods,
      recipe = setup.recipe,
      referencedRecipes = setup.referencedRecipes,
      ingredients = setup.ingredients,
      complexIngredients = setup.complexIngredients
    )
    val transformer = for {
      rescaledRecipe <- EitherT(services.rescaleService.rescale(setup.userId, setup.recipe.id))
      recipeWeight   <- EitherT.fromOptionF(
        services.statsService.weightOfRecipe(setup.userId, setup.recipe.id),
        ErrorContext.Recipe.NotFound.asServerError
      )
    } yield Prop.all(
      rescaledRecipe.copy(numberOfServings = setup.recipe.numberOfServings) ?= setup.recipe,
      PropUtil.closeEnough(Some(rescaledRecipe.numberOfServings * setup.servingSizeInGrams), Some(recipeWeight))
    )

    DBTestUtil.awaitProp(transformer)
  }

  property("Rescaling fails for wrong user id") = Prop.forAll(
    rescaleSetupGen :| "setup",
    GenUtils.taggedId(UserId) :| "userId2"
  ) { (setup, userId2) =>
    val services = servicesWith(
      userId = setup.userId,
      complexFoods = setup.complexFoods,
      recipe = setup.recipe,
      referencedRecipes = setup.referencedRecipes,
      ingredients = setup.ingredients,
      complexIngredients = setup.complexIngredients
    )
    val propF = for {
      result <- services.rescaleService.rescale(userId2, setup.recipe.id)
    } yield result.isLeft

    DBTestUtil.await(propF)
  }

  private val invalidServingSizeGen: Gen[RescaleSetup] = {
    val invalidNumber = for {
      letter   <- Gen.alphaChar
      rest     <- Arbitrary.arbitrary[String]
      permuted <- GenUtils.shuffle(letter +: rest.toList)
    } yield permuted.mkString
    val validNumber = for {
      positive <- Gen.posNum[BigDecimal]
    } yield positive.toString()
    val invalidUnit = for {
      string <- Arbitrary.arbitrary[String]
    } yield if (string == "g") "invalid" else string
    val invalidSizeGen = for {
      invalidCombination <- Gen.oneOf(
        (invalidNumber, Gen.const("g")).tupled,
        (validNumber, invalidUnit).tupled,
        (invalidNumber, invalidUnit).tupled
      )
      spaces <- Gen.choose(0, 25)
    } yield s"${invalidCombination._1}${List.fill(spaces)(' ').mkString}${invalidCombination._2}"
    for {
      base        <- rescaleSetupGen
      invalidSize <- Gen.option(invalidSizeGen)
    } yield base.copy(
      recipe = base.recipe.copy(
        servingSize = invalidSize
      )
    )
  }

  property("Rescaling fails invalid serving sizes") = Prop.forAll(invalidServingSizeGen :| "setup") { setup =>
    val services = servicesWith(
      userId = setup.userId,
      complexFoods = setup.complexFoods,
      recipe = setup.recipe,
      referencedRecipes = setup.referencedRecipes,
      ingredients = setup.ingredients,
      complexIngredients = setup.complexIngredients
    )
    val propF = for {
      result <- services.rescaleService.rescale(setup.userId, setup.recipe.id)
    } yield result.isLeft

    DBTestUtil.await(propF)
  }

}
