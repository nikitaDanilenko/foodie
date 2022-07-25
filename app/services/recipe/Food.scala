package services.recipe

import db.generated.Tables
import io.scalaland.chimney.Transformer
import services.FoodId
import utils.TransformerUtils.Implicits._

case class Food(
    id: FoodId,
    name: String
)

object Food {

  implicit val fromDB: Transformer[Tables.FoodNameRow, Food] =
    Transformer
      .define[Tables.FoodNameRow, Food]
      .withFieldRenamed(_.foodId, _.id)
      .withFieldRenamed(_.foodDescription, _.name)
      .buildTransformer

}
