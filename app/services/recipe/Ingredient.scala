package services.recipe

import db.generated.Tables
import db.{ FoodId, IngredientId, MeasureId, RecipeId, UserId }
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class Ingredient(
    id: IngredientId,
    foodId: FoodId,
    amountUnit: AmountUnit
)

object Ingredient {

  implicit val fromDB: Transformer[Tables.RecipeIngredientRow, Ingredient] =
    Transformer
      .define[Tables.RecipeIngredientRow, Ingredient]
      .withFieldComputed(_.id, _.id.transformInto[IngredientId])
      .withFieldComputed(_.foodId, _.foodNameId.transformInto[FoodId])
      .withFieldComputed(
        _.amountUnit,
        r =>
          AmountUnit(
            measureId = r.measureId.map(_.transformInto[MeasureId]),
            factor = r.factor
          )
      )
      .buildTransformer

  implicit val toDB: Transformer[(Ingredient, RecipeId, UserId), Tables.RecipeIngredientRow] = {
    case (ingredient, recipeId, userId) =>
      Tables.RecipeIngredientRow(
        id = ingredient.id.transformInto[UUID],
        recipeId = recipeId.transformInto[UUID],
        foodNameId = ingredient.foodId.transformInto[Int],
        measureId = ingredient.amountUnit.measureId.map(_.transformInto[Int]),
        factor = ingredient.amountUnit.factor,
        userId = userId.transformInto[UUID]
      )
  }

}
