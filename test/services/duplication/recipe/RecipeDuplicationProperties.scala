package services.duplication.recipe

import cats.data.EitherT
import cats.syntax.traverse._
import db.{ UserId, _ }
import errors.ServerError
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Gen, Prop, Properties }
import services.GenUtils.implicits._
import services.complex.food.ComplexFood
import services.complex.food.Gens.VolumeAmountOption
import services.complex.ingredient.{ ComplexIngredient, ComplexIngredientService }
import services.recipe._
import services.{ ContentsUtil, DBTestUtil, GenUtils, TestUtil }
import util.DateUtil

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object RecipeDuplicationProperties extends Properties("Recipe duplication") {

  case class Services(
      recipeService: RecipeService,
      complexIngredientService: ComplexIngredientService,
      duplication: Duplication
  )

  def servicesWith(
      userId: UserId,
      complexFoods: List[ComplexFood],
      recipe: Recipe,
      ingredients: List[Ingredient],
      complexIngredients: List[ComplexIngredient]
  ): Services = {
    val recipeDao      = DAOTestInstance.Recipe.instanceFrom(ContentsUtil.Recipe.from(userId, Seq(recipe)))
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

    Services(
      recipeService = new services.recipe.Live(
        TestUtil.databaseConfigProvider,
        recipeServiceCompanion
      ),
      complexIngredientService = new services.complex.ingredient.Live(
        TestUtil.databaseConfigProvider,
        complexIngredientServiceCompanion
      ),
      duplication = new services.duplication.recipe.Live(
        TestUtil.databaseConfigProvider,
        new services.duplication.recipe.Live.Companion(
          recipeServiceCompanion,
          ingredientDao,
          complexIngredientDao
        ),
        recipeServiceCompanion = recipeServiceCompanion,
        complexIngredientServiceCompanion = complexIngredientServiceCompanion
      )
    )
  }

  private case class DuplicationSetup(
      userId: UserId,
      recipe: Recipe,
      referencedRecipes: List[Recipe],
      complexFoods: List[ComplexFood],
      ingredients: List[Ingredient],
      complexIngredients: List[ComplexIngredient]
  )

  private val duplicationSetupGen: Gen[DuplicationSetup] = for {
    userId                <- GenUtils.taggedId(UserId)
    recipe                <- services.recipe.Gens.recipeGen
    referencedRecipes     <- Gen.nonEmptyListOf(services.recipe.Gens.recipeGen)
    subsetForComplexFoods <- GenUtils.subset(referencedRecipes)
    complexFoods          <- subsetForComplexFoods.traverse(
      services.complex.food.Gens.complexFood(_, VolumeAmountOption.OptionalVolume)
    )
    ingredients        <- Gen.listOf(services.recipe.Gens.ingredientGen)
    complexIngredients <- services.complex.ingredient.Gens.complexIngredientsGen(complexFoods)
  } yield DuplicationSetup(
    userId = userId,
    recipe = recipe,
    referencedRecipes = referencedRecipes,
    complexFoods = complexFoods,
    ingredients = ingredients,
    complexIngredients = complexIngredients
  )

  private case class IngredientValues(
      foodId: FoodId,
      amountUnit: AmountUnit
  )

  private def groupIngredients(ingredients: Seq[Ingredient]): Map[(FoodId, Option[MeasureId]), List[IngredientValues]] =
    ingredients
      .groupBy(ingredient => (ingredient.foodId, ingredient.amountUnit.measureId))
      .view
      .mapValues(
        _.sortBy(_.amountUnit.factor)
          .map(ingredient => IngredientValues(ingredient.foodId, ingredient.amountUnit))
          .toList
      )
      .toMap

  property("Duplication produces expected result") = Prop.forAll(duplicationSetupGen :| "setup") { setup =>
    val services = servicesWith(
      userId = setup.userId,
      complexFoods = setup.complexFoods,
      recipe = setup.recipe,
      ingredients = setup.ingredients,
      complexIngredients = setup.complexIngredients
    )
    val transformer = for {
      timestamp        <- EitherT.liftF(DateUtil.now)
      duplicatedRecipe <- EitherT(services.duplication.duplicate(setup.userId, setup.recipe.id, timestamp))
      ingredients      <- EitherT.liftF[Future, ServerError, List[Ingredient]](
        services.recipeService.getIngredients(setup.userId, duplicatedRecipe.id)
      )
      complexIngredients <- EitherT.liftF[Future, ServerError, Seq[ComplexIngredient]](
        services.complexIngredientService.all(setup.userId, duplicatedRecipe.id)
      )
    } yield {
      Prop.all(
        groupIngredients(ingredients) ?= groupIngredients(setup.ingredients),
        complexIngredients.sortBy(_.complexFoodId) ?= setup.complexIngredients.sortBy(_.complexFoodId),
        duplicatedRecipe.name.startsWith(setup.recipe.name),
        duplicatedRecipe.description ?= setup.recipe.description,
        duplicatedRecipe.numberOfServings ?= setup.recipe.numberOfServings,
        duplicatedRecipe.servingSize ?= setup.recipe.servingSize
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Duplication adds value") = Prop.forAll(duplicationSetupGen :| "setup") { setup =>
    val services = servicesWith(
      userId = setup.userId,
      complexFoods = setup.complexFoods,
      recipe = setup.recipe,
      ingredients = setup.ingredients,
      complexIngredients = setup.complexIngredients
    )
    val transformer = for {
      timestamp        <- EitherT.liftF(DateUtil.now)
      allRecipesBefore <- EitherT.liftF[Future, ServerError, Seq[Recipe]](
        services.recipeService.allRecipes(setup.userId)
      )
      duplicated      <- EitherT(services.duplication.duplicate(setup.userId, setup.recipe.id, timestamp))
      allRecipesAfter <- EitherT.liftF[Future, ServerError, Seq[Recipe]](
        services.recipeService.allRecipes(setup.userId)
      )
    } yield {
      allRecipesAfter.map(_.id).sorted ?= (allRecipesBefore :+ duplicated).map(_.id).sorted
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Duplication fails for wrong user id") = Prop.forAll(
    duplicationSetupGen :| "setup",
    GenUtils.taggedId(UserId) :| "userId2"
  ) { (setup, userId2) =>
    val services = servicesWith(
      userId = setup.userId,
      complexFoods = setup.complexFoods,
      recipe = setup.recipe,
      ingredients = setup.ingredients,
      complexIngredients = setup.complexIngredients
    )
    val propF = for {
      timestamp <- DateUtil.now
      result    <- services.duplication.duplicate(userId2, setup.recipe.id, timestamp)
    } yield result.isLeft

    DBTestUtil.await(propF)
  }
}
