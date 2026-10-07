package services.complex.food

import cats.data.{ EitherT, NonEmptyList }
import config.TestConfiguration
import db.{ UserId, _ }
import errors.ErrorContext
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Gen, Prop, Properties, Test }
import services.GenUtils.implicits._
import services.complex.food.Gens.VolumeAmountOption
import services.complex.ingredient.{ ComplexIngredient, ScalingMode }
import services.recipe.{ Recipe, RecipeServiceProperties }
import services.{ ContentsUtil, DBTestUtil, GenUtils, TestUtil }

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object ComplexFoodServiceProperties extends Properties("Complex food service") {

  def companionWith(
      recipeContents: Seq[(UserId, Recipe)],
      complexFoodContents: Seq[(UserId, RecipeId, ComplexFood)],
      complexIngredientContents: Seq[(UserId, RecipeId, ComplexIngredient)]
  ): Live.Companion =
    new Live.Companion(
      recipeService = RecipeServiceProperties.companionWith(
        recipeContents = recipeContents,
        ingredientContents = Seq.empty
      ),
      dao = DAOTestInstance.ComplexFood.instanceFrom(complexFoodContents),
      complexIngredientDao = DAOTestInstance.ComplexIngredient.instanceFrom(complexIngredientContents)
    )

  private def complexFoodServiceWith(
      recipeContents: Seq[(UserId, Recipe)],
      complexFoodContents: Seq[(UserId, RecipeId, ComplexFood)],
      complexIngredientContents: Seq[(UserId, RecipeId, ComplexIngredient)]
  ): ComplexFoodService =
    new Live(
      dbConfigProvider = TestUtil.databaseConfigProvider,
      companion = companionWith(
        recipeContents = recipeContents,
        complexFoodContents = complexFoodContents,
        complexIngredientContents = complexIngredientContents
      )
    )

  private case class SetupBase(
      userId: UserId,
      recipes: Seq[Recipe],
      complexFoods: Seq[ComplexFood]
  )

  private val setupBaseGen: Gen[SetupBase] = for {
    userId        <- GenUtils.taggedId(UserId)
    recipes       <- Gen.nonEmptyListOf(services.recipe.Gens.recipeGen)
    recipesSubset <- GenUtils.nonEmptySubset(NonEmptyList.fromListUnsafe(recipes))
    complexFoods  <- recipesSubset.traverse(Gens.complexFood(_, VolumeAmountOption.OptionalVolume))
  } yield SetupBase(
    userId = userId,
    recipes = recipes,
    complexFoods = complexFoods.toList
  )

  private case class FetchAllSetup(
      userId: UserId,
      recipes: Seq[Recipe],
      complexFoods: Seq[ComplexFood]
  )

  private val fetchAllSetupGen: Gen[FetchAllSetup] = for {
    base <- setupBaseGen
  } yield FetchAllSetup(
    userId = base.userId,
    recipes = base.recipes,
    complexFoods = base.complexFoods.toList
  )

  property("Fetch all") = Prop.forAll(fetchAllSetupGen :| "setup") { setup =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, setup.recipes),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.userId, setup.complexFoods),
      complexIngredientContents = Seq.empty
    )
    val propF = for {
      all <- complexFoodService.all(setup.userId)
    } yield {
      val expected = setup.complexFoods
      all.sortBy(_.recipeId) ?= expected.sortBy(_.recipeId)
    }

    DBTestUtil.await(propF)
  }

  private case class FetchSingleSetup(
      userId: UserId,
      recipes: Seq[Recipe],
      complexFoods: Seq[ComplexFood],
      complexFoodId: ComplexFoodId
  )

  private val fetchSingleSetupGen: Gen[FetchSingleSetup] = for {
    base          <- setupBaseGen
    complexFoodId <- Gen.oneOf(base.complexFoods.map(_.recipeId))
  } yield FetchSingleSetup(
    userId = base.userId,
    recipes = base.recipes,
    complexFoods = base.complexFoods,
    complexFoodId = complexFoodId
  )

  property("Fetch single") = Prop.forAll(fetchSingleSetupGen :| "setup") { setup =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, setup.recipes),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.userId, setup.complexFoods),
      complexIngredientContents = Seq.empty
    )
    val transformer = for {
      complexFood <- EitherT.fromOptionF(
        complexFoodService.get(setup.userId, setup.complexFoodId),
        ErrorContext.ComplexFood.NotFound.asServerError
      )
      _ <- EitherT.fromOption[Future](
        setup.recipes.find(_.id == setup.complexFoodId),
        ErrorContext.Recipe.NotFound.asServerError
      )
      expected <- EitherT.fromOption[Future](
        setup.complexFoods.find(_.recipeId == setup.complexFoodId),
        ErrorContext.ComplexFood.NotFound.asServerError
      )
    } yield complexFood ?= expected

    DBTestUtil.awaitProp(transformer)
  }

  private case class CreationSetup(
      userId: UserId,
      recipe: Recipe,
      complexFoodCreation: ComplexFoodCreation
  )

  private object CreationSetup {

    def complexFoodOf(creationSetup: CreationSetup): ComplexFood = ComplexFoodCreation.create(
      creationSetup.recipe.name,
      creationSetup.recipe.description,
      creationSetup.complexFoodCreation
    )

  }

  private def creationSetupGenWith(volumeAmountOption: VolumeAmountOption): Gen[CreationSetup] = for {
    userId              <- GenUtils.taggedId(UserId)
    recipe              <- services.recipe.Gens.recipeGen
    complexFoodCreation <- Gens.complexFoodCreation(recipe.id, volumeAmountOption)
  } yield CreationSetup(
    userId = userId,
    recipe = recipe,
    complexFoodCreation = complexFoodCreation
  )

  private val creationSetupGen: Gen[CreationSetup] = creationSetupGenWith(VolumeAmountOption.OptionalVolume)

  property("Creation (success)") = Prop.forAll(creationSetupGen :| "setup") { setup =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.recipe)),
      complexFoodContents = Seq.empty,
      complexIngredientContents = Seq.empty
    )
    val transformer = for {
      inserted <- EitherT(complexFoodService.create(setup.userId, setup.complexFoodCreation))
      fetched  <- EitherT.fromOptionF(
        complexFoodService.get(setup.userId, setup.complexFoodCreation.recipeId),
        ErrorContext.ComplexFood.NotFound.asServerError
      )
    } yield {
      val expected = CreationSetup.complexFoodOf(setup)
      Prop.all(
        inserted ?= expected,
        fetched ?= expected
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Creation (failure)") = Prop.forAll(creationSetupGen :| "setup") { setup =>
    val complexFood        = CreationSetup.complexFoodOf(setup)
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.userId, Seq(complexFood)),
      complexIngredientContents = Seq.empty
    )
    val propF = for {
      created <- complexFoodService.create(setup.userId, setup.complexFoodCreation)
    } yield created.isLeft

    DBTestUtil.await(propF)
  }

  private case class UpdateSetup(
      creationSetup: CreationSetup,
      update: ComplexFoodUpdate
  )

  private def updateSetupGenWith(
      creationVolumeAmountOption: VolumeAmountOption,
      updateVolumeAmountOption: VolumeAmountOption
  ): Gen[UpdateSetup] = for {
    creationSetup <- creationSetupGenWith(creationVolumeAmountOption)
    update        <- Gens.complexFoodUpdate(updateVolumeAmountOption)
  } yield UpdateSetup(
    creationSetup = creationSetup,
    update = update
  )

  private val updateSetupGen: Gen[UpdateSetup] = updateSetupGenWith(
    VolumeAmountOption.OptionalVolume,
    VolumeAmountOption.OptionalVolume
  )

  property("Update (success)") = Prop.forAll(updateSetupGen :| "setup") { setup =>
    val complexFood        = CreationSetup.complexFoodOf(setup.creationSetup)
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.creationSetup.userId, Seq(setup.creationSetup.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.creationSetup.userId, Seq(complexFood)),
      complexIngredientContents = Seq.empty
    )
    val transformer = for {
      updated <- EitherT(
        complexFoodService.update(
          setup.creationSetup.userId,
          setup.creationSetup.complexFoodCreation.recipeId,
          setup.update
        )
      )
      fetched <- EitherT.fromOptionF(
        complexFoodService.get(setup.creationSetup.userId, setup.creationSetup.complexFoodCreation.recipeId),
        ErrorContext.ComplexFood.NotFound.asServerError
      )
    } yield {
      val expected = ComplexFoodUpdate.update(complexFood, setup.update)
      Prop.all(
        updated ?= expected,
        fetched ?= expected
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Update (failure)") = Prop.forAll(updateSetupGen :| "setup") { setup =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.creationSetup.userId, Seq(setup.creationSetup.recipe)),
      complexFoodContents = Seq.empty,
      complexIngredientContents = Seq.empty
    )
    val propF = for {
      result <- complexFoodService.update(setup.creationSetup.userId, setup.creationSetup.recipe.id, setup.update)
    } yield result.isLeft

    DBTestUtil.await(propF)
  }

  private case class UpdateFailureVolumeDependencySetup(
      updateSetup: UpdateSetup,
      recipeForReferencingIngredient: Recipe,
      referencingComplexIngredient: ComplexIngredient
  )

  private val updateFailureVolumeDependencySetupGen: Gen[UpdateFailureVolumeDependencySetup] = for {
    updateSetup <- updateSetupGenWith(
      creationVolumeAmountOption = VolumeAmountOption.DefinedVolume,
      updateVolumeAmountOption = VolumeAmountOption.NoVolume
    )
    recipe            <- services.recipe.Gens.recipeGen
    complexIngredient <- services.complex.ingredient.Gens.complexIngredientGen(
      complexFoods = Seq(CreationSetup.complexFoodOf(updateSetup.creationSetup))
    )
  } yield UpdateFailureVolumeDependencySetup(
    updateSetup = updateSetup,
    recipeForReferencingIngredient = recipe,
    referencingComplexIngredient = complexIngredient.copy(
      scalingMode = ScalingMode.Volume
    )
  )

  property("Update (failure, deleting volume with references is impossible)") = Prop.forAll(
    updateFailureVolumeDependencySetupGen :| "setup"
  ) { setup =>
    val complexFood        = CreationSetup.complexFoodOf(setup.updateSetup.creationSetup)
    val userId             = setup.updateSetup.creationSetup.userId
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(
        userId,
        Seq(setup.updateSetup.creationSetup.recipe, setup.recipeForReferencingIngredient)
      ),
      complexFoodContents = ContentsUtil.ComplexFood.from(userId, Seq(complexFood)),
      complexIngredientContents = ContentsUtil.ComplexIngredient
        .from(
          userId,
          setup.recipeForReferencingIngredient.id,
          Seq(setup.referencingComplexIngredient)
        )
    )

    val propF = for {
      result <- complexFoodService.update(
        setup.updateSetup.creationSetup.userId,
        setup.referencingComplexIngredient.complexFoodId,
        setup.updateSetup.update
      )
    } yield result.isLeft

    DBTestUtil.await(propF)
  }

  property("Delete (existent)") = Prop.forAll(creationSetupGen :| "setup") { setup =>
    val complexFood        = CreationSetup.complexFoodOf(setup)
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.userId, Seq(complexFood)),
      complexIngredientContents = Seq.empty
    )
    val propF = for {
      result  <- complexFoodService.delete(setup.userId, setup.recipe.id)
      fetched <- complexFoodService.get(setup.userId, setup.recipe.id)
    } yield Prop.all(
      result,
      fetched.isEmpty
    )

    DBTestUtil.await(propF)
  }

  property("Delete (non-existent)") = Prop.forAll(creationSetupGen :| "setup") { setup =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.recipe)),
      complexFoodContents = Seq.empty,
      complexIngredientContents = Seq.empty
    )
    val propF = for {
      result <- complexFoodService.delete(setup.userId, setup.recipe.id)
    } yield !result

    DBTestUtil.await(propF)
  }

  property("Fetch all (wrong user)") = Prop.forAll(
    fetchAllSetupGen :| "setup",
    GenUtils.taggedId(UserId) :| "userId2"
  ) { (setup, userId2) =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, setup.recipes),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.userId, setup.complexFoods),
      complexIngredientContents = Seq.empty
    )

    val propF = for {
      all <- complexFoodService.all(userId2)
    } yield {
      all.isEmpty
    }

    DBTestUtil.await(propF)
  }

  property("Fetch single (wrong user)") = Prop.forAll(
    fetchSingleSetupGen :| "setup",
    GenUtils.taggedId(UserId) :| "userId2"
  ) { (setup, userId2) =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, setup.recipes),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.userId, setup.complexFoods),
      complexIngredientContents = Seq.empty
    )
    val propF = for {
      result <- complexFoodService.get(userId2, setup.complexFoodId)
    } yield result.isEmpty

    DBTestUtil.await(propF)
  }

  property("Creation (wrong user)") = Prop.forAll(
    creationSetupGen :| "setup",
    GenUtils.taggedId(UserId) :| "userId2"
  ) { (setup, userId2) =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.recipe)),
      complexFoodContents = Seq.empty,
      complexIngredientContents = Seq.empty
    )
    val propF = for {
      result <- complexFoodService.create(userId2, setup.complexFoodCreation)
    } yield result.isLeft

    DBTestUtil.await(propF)
  }

  property("Update (wrong user)") = Prop.forAll(
    updateSetupGen :| "setup",
    GenUtils.taggedId(UserId) :| "userId2"
  ) { (setup, userId2) =>
    val userId             = setup.creationSetup.userId
    val complexFood        = CreationSetup.complexFoodOf(setup.creationSetup)
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(userId, Seq(setup.creationSetup.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(userId, Seq(complexFood)),
      complexIngredientContents = Seq.empty
    )
    val transformer = for {
      result <- EitherT.liftF(
        complexFoodService.update(userId2, setup.creationSetup.complexFoodCreation.recipeId, setup.update)
      )
      fetched <- EitherT.fromOptionF(
        complexFoodService.get(userId, setup.creationSetup.complexFoodCreation.recipeId),
        ErrorContext.ComplexFood.NotFound.asServerError
      )
    } yield {
      Prop.all(
        result.isLeft,
        fetched ?= complexFood
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Delete (wrong user)") = Prop.forAll(
    creationSetupGen :| "setup",
    GenUtils.taggedId(UserId) :| "userId2"
  ) { (setup, userId2) =>
    val complexFood        = CreationSetup.complexFoodOf(setup)
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.userId, Seq(complexFood)),
      complexIngredientContents = Seq.empty
    )
    val transformer = for {
      result  <- EitherT.liftF(complexFoodService.delete(userId2, setup.recipe.id))
      fetched <- EitherT.fromOptionF(
        complexFoodService.get(setup.userId, setup.complexFoodCreation.recipeId),
        ErrorContext.ComplexFood.NotFound.asServerError
      )
    } yield Prop.all(
      !result,
      fetched ?= complexFood
    )

    DBTestUtil.awaitProp(transformer)
  }

  override def overrideParameters(p: Test.Parameters): Test.Parameters =
    p.withMinSuccessfulTests(TestConfiguration.default.property.minSuccessfulTests.withoutDB)

}
