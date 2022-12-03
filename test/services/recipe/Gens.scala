package services.recipe

import io.scalaland.chimney.dsl._
import org.scalacheck.Gen
import services._
import spire.math.Natural
import utils.TransformerUtils.Implicits._

object Gens {

  val recipeCreationGen: Gen[RecipeCreation] = for {
    name             <- GenUtils.nonEmptyAsciiString
    description      <- Gen.option(GenUtils.nonEmptyAsciiString)
    numberOfServings <- GenUtils.smallBigDecimalGen
  } yield RecipeCreation(
    name = name,
    description = description,
    numberOfServings = numberOfServings
  )

  val ingredientGen: Gen[IngredientParameters] =
    for {
      food         <- GenUtils.foodGen
      measureId    <- GenUtils.optionalOneOf(food.measures.map(_.id))
      factor       <- GenUtils.smallBigDecimalGen
      ingredientId <- Gen.uuid.map(_.transformInto[IngredientId])
    } yield IngredientParameters(
      ingredientId = ingredientId,
      ingredientPreCreation = IngredientPreCreation(
        foodId = food.id,
        amountUnit = AmountUnit(
          measureId = measureId,
          factor = factor
        )
      )
    )

  val recipeParametersGen: Gen[RecipeParameters] = for {
    recipeCreation       <- recipeCreationGen
    ingredientParameters <- GenUtils.listOfAtMost(Natural(20), ingredientGen)
  } yield RecipeParameters(
    recipeCreation = recipeCreation,
    ingredientParameters = ingredientParameters
  )

}