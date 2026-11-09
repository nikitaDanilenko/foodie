package services.recipe

import cats.data.EitherT
import config.TestConfiguration
import db.{ UserId, _ }
import errors.{ ErrorContext, ServerError }
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Gen, Prop, Properties, Test }
import services.{ ContentsUtil, DBTestUtil, GenUtils, TestUtil }

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object RecipeServiceProperties extends Properties("Recipe service") {

  def companionWith(
      recipeContents: Seq[(UserId, Recipe)],
      ingredientContents: Seq[(UserId, RecipeId, Ingredient)]
  ): services.recipe.Live.Companion =
    new services.recipe.Live.Companion(
      recipeDao = DAOTestInstance.Recipe.instanceFrom(recipeContents),
      ingredientDao = DAOTestInstance.Ingredient.instanceFrom(ingredientContents),
      generalTableConstants = DBTestUtil.generalTableConstants
    )

  def recipeServiceWith(
      recipeContents: Seq[(UserId, Recipe)],
      ingredientContents: Seq[(UserId, RecipeId, Ingredient)]
  ): RecipeService =
    new services.recipe.Live(
      dbConfigProvider = TestUtil.databaseConfigProvider,
      companion = companionWith(
        recipeContents = recipeContents,
        ingredientContents = ingredientContents
      )
    )

  property("Creation") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId",
    Gens.recipeCreationGen :| "recipe"
  ) { (userId, recipeCreation) =>
    val recipeService = recipeServiceWith(
      recipeContents = Seq.empty,
      ingredientContents = Seq.empty
    )
    val transformer = for {
      createdRecipe <- EitherT(recipeService.createRecipe(userId, recipeCreation))
      fetchedRecipe <- EitherT.fromOptionF(
        recipeService.getRecipe(userId, createdRecipe.id),
        ErrorContext.Recipe.NotFound.asServerError
      )
    } yield {
      val expectedRecipe = RecipeCreation.create(createdRecipe.id, recipeCreation)
      Prop.all(
        createdRecipe ?= expectedRecipe,
        fetchedRecipe ?= expectedRecipe
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Read single") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId",
    Gens.recipeGen :| "recipe"
  ) { (userId, recipe) =>
    val recipeService = recipeServiceWith(
      recipeContents = ContentsUtil.Recipe.from(userId, Seq(recipe)),
      ingredientContents = Seq.empty
    )
    val transformer = for {
      fetchedRecipe <- EitherT.fromOptionF(
        recipeService.getRecipe(userId, recipe.id),
        ErrorContext.Recipe.NotFound.asServerError
      )
    } yield fetchedRecipe ?= recipe

    DBTestUtil.awaitProp(transformer)
  }

  property("Read all") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId",
    Gen.listOf(Gens.recipeGen) :| "recipes"
  ) { (userId, recipes) =>
    val recipeService = recipeServiceWith(
      recipeContents = ContentsUtil.Recipe.from(userId, recipes),
      ingredientContents = Seq.empty
    )
    val transformer = for {
      fetchedRecipes <- EitherT.liftF[Future, ServerError, Seq[Recipe]](
        recipeService.allRecipes(userId)
      )
    } yield fetchedRecipes.sortBy(_.id) ?= recipes.sortBy(_.id)

    DBTestUtil.awaitProp(transformer)
  }

  private case class UpdateSetup(
      userId: UserId,
      recipe: Recipe,
      recipeUpdate: RecipeUpdate
  )

  private val updateSetupGen: Gen[UpdateSetup] =
    for {
      userId       <- GenUtils.taggedId(UserId)
      recipe       <- Gens.recipeGen
      recipeUpdate <- Gens.recipeUpdateGen
    } yield UpdateSetup(
      userId,
      recipe,
      recipeUpdate
    )

  property("Update") = Prop.forAll(
    updateSetupGen :| "update setup"
  ) { updateSetup =>
    val recipeService = recipeServiceWith(
      recipeContents = ContentsUtil.Recipe.from(updateSetup.userId, Seq(updateSetup.recipe)),
      ingredientContents = Seq.empty
    )
    val transformer = for {
      updatedRecipe <- EitherT(
        recipeService.updateRecipe(updateSetup.userId, updateSetup.recipe.id, updateSetup.recipeUpdate)
      )
      fetchedRecipe <- EitherT.fromOptionF(
        recipeService.getRecipe(updateSetup.userId, updateSetup.recipe.id),
        ErrorContext.Recipe.NotFound.asServerError
      )
    } yield {
      val expectedRecipe = RecipeUpdate.update(updateSetup.recipe, updateSetup.recipeUpdate)
      Prop.all(
        updatedRecipe ?= expectedRecipe,
        fetchedRecipe ?= expectedRecipe
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Delete") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId",
    Gens.recipeGen :| "recipe"
  ) { (userId, recipe) =>
    val recipeService = recipeServiceWith(
      recipeContents = ContentsUtil.Recipe.from(userId, Seq(recipe)),
      ingredientContents = Seq.empty
    )
    val transformer = for {
      result  <- EitherT.liftF[Future, ServerError, Boolean](recipeService.deleteRecipe(userId, recipe.id))
      fetched <- EitherT.liftF[Future, ServerError, Option[Recipe]](recipeService.getRecipe(userId, recipe.id))
    } yield Prop.all(
      Prop(result) :| "Deletion successful",
      Prop(fetched.isEmpty) :| "Recipe should be deleted"
    )

    DBTestUtil.awaitProp(transformer)
  }

  property("Add ingredient") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId",
    Gens.fullRecipeGen() :| "full recipe",
    Gens.ingredientGen :| "ingredient"
  ) { (userId, fullRecipe, ingredient) =>
    val recipeService = recipeServiceWith(
      recipeContents = ContentsUtil.Recipe.from(userId, Seq(fullRecipe.recipe)),
      ingredientContents = ContentsUtil.Ingredient.from(userId, fullRecipe)
    )
    val ingredientCreation = IngredientCreation(ingredient.foodId, ingredient.amountUnit)
    val transformer        = for {
      ingredient  <- EitherT(recipeService.addIngredient(userId, fullRecipe.recipe.id, ingredientCreation))
      ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
        recipeService.getIngredients(userId, fullRecipe.recipe.id)
      )
    } yield {
      val expectedIngredient = IngredientCreation.create(ingredient.id, ingredientCreation)
      ingredients.sortBy(_.id) ?= (expectedIngredient +: fullRecipe.ingredients).sortBy(_.id)
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Read ingredients") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId",
    Gens.fullRecipeGen() :| "full recipe"
  ) { (userId, fullRecipe) =>
    val recipeService = recipeServiceWith(
      recipeContents = ContentsUtil.Recipe.from(userId, Seq(fullRecipe.recipe)),
      ingredientContents = ContentsUtil.Ingredient.from(userId, fullRecipe)
    )
    val transformer = for {
      ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
        recipeService.getIngredients(userId, fullRecipe.recipe.id)
      )
    } yield ingredients.sortBy(_.id) ?= fullRecipe.ingredients.sortBy(_.id)

    DBTestUtil.awaitProp(transformer)
  }

  private case class IngredientUpdateSetup(
      userId: UserId,
      fullRecipe: FullRecipe,
      ingredient: Ingredient,
      ingredientUpdate: IngredientUpdate
  )

  private val ingredientUpdateSetupGen: Gen[IngredientUpdateSetup] =
    for {
      userId           <- GenUtils.taggedId(UserId)
      fullRecipe       <- Gens.fullRecipeGen()
      ingredient       <- Gen.oneOf(fullRecipe.ingredients)
      ingredientUpdate <- Gens.ingredientUpdateGen(ingredient.foodId)
    } yield IngredientUpdateSetup(
      userId = userId,
      fullRecipe = fullRecipe,
      ingredient = ingredient,
      ingredientUpdate = ingredientUpdate
    )

  property("Update ingredient") = Prop.forAll(
    ingredientUpdateSetupGen :| "ingredient update setup"
  ) { setup =>
    val recipeService = recipeServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.fullRecipe.recipe)),
      ingredientContents = ContentsUtil.Ingredient.from(setup.userId, setup.fullRecipe)
    )

    val transformer = for {
      updatedIngredient <- EitherT(
        recipeService.updateIngredient(
          setup.userId,
          setup.fullRecipe.recipe.id,
          setup.ingredient.id,
          setup.ingredientUpdate
        )
      )
      ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
        recipeService.getIngredients(setup.userId, setup.fullRecipe.recipe.id)
      )
    } yield {
      val expectedIngredient = IngredientUpdate.update(
        setup.ingredient,
        setup.ingredientUpdate
      )
      val expectedIngredients =
        setup.fullRecipe.ingredients.map { ingredient =>
          if (ingredient.id == setup.ingredient.id) expectedIngredient
          else ingredient
        }
      Prop.all(
        (updatedIngredient ?= expectedIngredient) :| "Update correct",
        (ingredients.sortBy(_.id) ?= expectedIngredients.sortBy(_.id)) :| "Ingredients after update correct"
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  private case class DeleteIngredientSetup(
      userId: UserId,
      fullRecipe: FullRecipe,
      ingredientId: IngredientId
  )

  private val deleteIngredientSetupGen: Gen[DeleteIngredientSetup] =
    for {
      userId       <- GenUtils.taggedId(UserId)
      fullRecipe   <- Gens.fullRecipeGen()
      ingredientId <- Gen.oneOf(fullRecipe.ingredients).map(_.id)
    } yield DeleteIngredientSetup(
      userId = userId,
      fullRecipe = fullRecipe,
      ingredientId = ingredientId
    )

  property("Delete ingredient") = Prop.forAll(
    deleteIngredientSetupGen :| "delete ingredient setup"
  ) { setup =>
    val recipeService = recipeServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.fullRecipe.recipe)),
      ingredientContents = ContentsUtil.Ingredient.from(setup.userId, setup.fullRecipe)
    )

    val transformer = for {
      deletionResult <- EitherT.liftF(
        recipeService.removeIngredient(setup.userId, setup.fullRecipe.recipe.id, setup.ingredientId)
      )
      ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
        recipeService.getIngredients(setup.userId, setup.fullRecipe.recipe.id)
      )
    } yield {
      val expectedIngredients = setup.fullRecipe.ingredients.filter(_.id != setup.ingredientId)
      Prop.all(
        Prop(deletionResult) :| "Deletion successful",
        (ingredients.sortBy(_.id) ?= expectedIngredients.sortBy(_.id)) :| "Ingredients after update correct"
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Creation (wrong user)") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId1",
    GenUtils.taggedId(UserId) :| "userId2",
    Gens.recipeCreationGen :| "recipe creation"
  ) { case (userId1, userId2, recipeCreation) =>
    val recipeService = recipeServiceWith(
      recipeContents = Seq.empty,
      ingredientContents = Seq.empty
    )
    val transformer = for {
      createdRecipe <- EitherT(recipeService.createRecipe(userId1, recipeCreation))
      fetchedRecipe <-
        EitherT.liftF[Future, ServerError, Option[Recipe]](recipeService.getRecipe(userId2, createdRecipe.id))
    } yield Prop(fetchedRecipe.isEmpty) :| "Access denied"

    DBTestUtil.awaitProp(transformer)
  }

  property("Read single (wrong user)") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId1",
    GenUtils.taggedId(UserId) :| "userId2",
    Gens.recipeGen :| "recipe"
  ) { case (userId1, userId2, recipe) =>
    val recipeService = recipeServiceWith(
      recipeContents = ContentsUtil.Recipe.from(userId1, Seq(recipe)),
      ingredientContents = Seq.empty
    )
    val transformer = for {
      fetchedRecipe <- EitherT.liftF[Future, ServerError, Option[Recipe]](
        recipeService.getRecipe(userId2, recipe.id)
      )
    } yield Prop(fetchedRecipe.isEmpty) :| "Access denied"

    DBTestUtil.awaitProp(transformer)
  }

  property("Read all (wrong user)") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId1",
    GenUtils.taggedId(UserId) :| "userId2",
    Gen.listOf(Gens.recipeGen) :| "recipes"
  ) { case (userId1, userId2, recipes) =>
    val recipeService = recipeServiceWith(
      recipeContents = ContentsUtil.Recipe.from(userId1, recipes),
      ingredientContents = Seq.empty
    )
    val transformer = for {
      fetchedRecipes <- EitherT.liftF[Future, ServerError, Seq[Recipe]](
        recipeService.allRecipes(userId2)
      )
    } yield fetchedRecipes ?= Seq.empty

    DBTestUtil.awaitProp(transformer)
  }

  // TODO: Add other mismatches as well.
  property("Update (wrong user)") = Prop.forAll(
    updateSetupGen :| "setup",
    GenUtils.taggedId(UserId) :| "userId2"
  ) { (setup, userId2) =>
    val recipeService = recipeServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.recipe)),
      ingredientContents = Seq.empty
    )
    val transformer = for {
      updatedRecipe <- EitherT.liftF[Future, ServerError, ServerError.Or[Recipe]](
        recipeService.updateRecipe(userId2, setup.recipe.id, setup.recipeUpdate)
      )
    } yield Prop(updatedRecipe.isLeft)

    DBTestUtil.awaitProp(transformer)
  }

  property("Delete (wrong user)") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId1",
    GenUtils.taggedId(UserId) :| "userId2",
    Gens.recipeGen :| "recipe"
  ) { case (userId1, userId2, recipe) =>
    val recipeService = recipeServiceWith(
      recipeContents = ContentsUtil.Recipe.from(userId1, Seq(recipe)),
      ingredientContents = Seq.empty
    )
    val transformer = for {
      result <- EitherT.liftF[Future, ServerError, Boolean](recipeService.deleteRecipe(userId2, recipe.id))
    } yield Prop(!result) :| "Deletion failed"

    DBTestUtil.awaitProp(transformer)
  }

  // TODO: There should be another property test for the other mismatch (userId/recipeId)
  property("Add ingredient (wrong user)") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId1",
    GenUtils.taggedId(UserId) :| "userId2",
    Gens.fullRecipeGen() :| "full recipe",
    Gens.ingredientGen :| "ingredient"
  ) { case (userId1, userId2, fullRecipe, ingredient) =>
    val recipeService = recipeServiceWith(
      recipeContents = ContentsUtil.Recipe.from(userId1, Seq(fullRecipe.recipe)),
      ingredientContents = ContentsUtil.Ingredient.from(userId1, fullRecipe)
    )
    val ingredientCreation = IngredientCreation(ingredient.foodId, ingredient.amountUnit)
    val transformer        = for {
      result      <- EitherT.liftF(recipeService.addIngredient(userId2, fullRecipe.recipe.id, ingredientCreation))
      ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
        recipeService.getIngredients(userId1, fullRecipe.recipe.id)
      )
    } yield Prop.all(
      Prop(result.isLeft) :| "Ingredient addition failed",
      ingredients.sortBy(_.id) ?= fullRecipe.ingredients.sortBy(_.id)
    )

    DBTestUtil.awaitProp(transformer)
  }

  property("Read ingredients (wrong user)") = Prop.forAll(
    GenUtils.taggedId(UserId) :| "userId1",
    GenUtils.taggedId(UserId) :| "userId2",
    Gens.fullRecipeGen() :| "full recipe"
  ) { case (userId1, userId2, fullRecipe) =>
    val recipeService = recipeServiceWith(
      recipeContents = ContentsUtil.Recipe.from(userId1, Seq(fullRecipe.recipe)),
      ingredientContents = ContentsUtil.Ingredient.from(userId1, fullRecipe)
    )
    val transformer = for {
      ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
        recipeService.getIngredients(userId2, fullRecipe.recipe.id)
      )
    } yield ingredients.sortBy(_.id) ?= List.empty

    DBTestUtil.awaitProp(transformer)
  }

  // TODO: There should be properties for other userId/recipeId mismatches as well
  property("Update ingredient (wrong user)") = Prop.forAll(
    ingredientUpdateSetupGen :| "ingredient update setup",
    GenUtils.taggedId(UserId) :| "userId2"
  ) { (setup, userId2) =>
    val recipeService = recipeServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.fullRecipe.recipe)),
      ingredientContents = ContentsUtil.Ingredient.from(setup.userId, setup.fullRecipe)
    )
    val transformer = for {
      result <- EitherT.liftF(
        recipeService.updateIngredient(userId2, setup.fullRecipe.recipe.id, setup.ingredient.id, setup.ingredientUpdate)
      )
      ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
        recipeService
          .getIngredients(setup.userId, setup.fullRecipe.recipe.id)
      )
    } yield Prop.all(
      Prop(result.isLeft) :| "Ingredient update failed",
      (ingredients.sortBy(_.id) ?= setup.fullRecipe.ingredients.sortBy(
        _.id
      )) :| "Ingredients after update correct"
    )

    DBTestUtil.awaitProp(transformer)
  }

  // TODO: There should be properties for other userId/recipeId mismatches as well
  property("Delete ingredient (wrong user)") = Prop.forAll(
    deleteIngredientSetupGen :| "wrong delete ingredient setup",
    GenUtils.taggedId(UserId) :| "userId2"
  ) { (setup, userId2) =>
    val recipeService = recipeServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.fullRecipe.recipe)),
      ingredientContents = ContentsUtil.Ingredient.from(setup.userId, setup.fullRecipe)
    )
    val transformer = for {
      deletionResult <- EitherT.liftF(
        recipeService.removeIngredient(userId2, setup.fullRecipe.recipe.id, setup.ingredientId)
      )
      ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
        recipeService.getIngredients(setup.userId, setup.fullRecipe.recipe.id)
      )
    } yield {
      val expectedIngredients = setup.fullRecipe.ingredients
      Prop.all(
        Prop(!deletionResult) :| "Ingredient deletion failed",
        (ingredients.sortBy(_.id) ?= expectedIngredients.sortBy(_.id)) :| "Ingredients after update correct"
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  override def overrideParameters(p: Test.Parameters): Test.Parameters =
    p.withMinSuccessfulTests(TestConfiguration.default.property.minSuccessfulTests.withoutDB)

}
