package services.recipe

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import services.{ RecipeId, UserId }
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class Recipe(
    id: RecipeId,
    name: String,
    description: Option[String],
    numberOfServings: BigDecimal
)

object Recipe {

  implicit val fromDB: Transformer[Tables.RecipeRow, Recipe] =
    Transformer
      .define[Tables.RecipeRow, Recipe]
      .buildTransformer

  implicit val toDB: Transformer[(Recipe, UserId), Tables.RecipeRow] = {
    case (recipe, userId) =>
      Tables.RecipeRow(
        id = recipe.id.transformInto[UUID],
        userId = userId.transformInto[UUID],
        name = recipe.name,
        description = recipe.description,
        numberOfServings = recipe.numberOfServings
      )

  }

}
